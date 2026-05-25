import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/screens/passenger_details_screen.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/cinema/cinema_screen_painter.dart';
import 'package:movieticket/widgets/cinema/seat_legend.dart';
import 'package:movieticket/widgets/cinema/seat_widget.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/app_appbar.dart';
import 'package:movieticket/widgets/common/app_loader.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:provider/provider.dart';

class SeatSelection extends StatefulWidget {
  final TmdbMovie movie;
  final String theatreName;
  final String theatreAddress;
  final String theatreLogo;
  final String cinemaId;
  final String preSelectedTime;

  const SeatSelection({
    super.key,
    required this.movie,
    required this.theatreName,
    required this.theatreAddress,
    required this.theatreLogo,
    required this.cinemaId,
    required this.preSelectedTime,
  });

  @override
  State<SeatSelection> createState() => _SeatSelectionState();
}

class _SeatSelectionState extends State<SeatSelection> {
  final List<List<int>> _seatLayout = [
    [4, 9], // Classic  rows A-D
    [3, 9], // Premium  rows E-G
    [2, 9], // VIP      rows H-I
  ];

  List<String> _selected = [];
  List<String> _booked = [];
  Map<String, Map<String, dynamic>> _locked = {};

  int _dateIndex = 0;
  int _timeIndex = 0;
  String _selectedTime = '';
  String _selectedDate = '';
  bool _isLoadingSeats = false;
  bool _isProceedLoading = false;

  final List<String> _showTimes = [
    '10:00 AM',
    '1:00 PM',
    '4:00 PM',
    '7:00 PM',
    '10:00 PM',
  ];

  late List<Map<String, dynamic>> _dates;

  static const Color _classicColor = Color(0xFF1E3A8A);
  static const Color _premiumColor = Color(0xFF6D28D9);
  static const Color _vipColor = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    _generateDates();

    // BUG FIX: Use preSelectedTime from cinema screen
    if (widget.preSelectedTime.isNotEmpty) {
      final idx = _showTimes.indexOf(
        widget.preSelectedTime,
      );
      _timeIndex = idx >= 0 ? idx : 0;
    }

    _selectedTime = _showTimes[_timeIndex];
    _selectedDate = _dates[_dateIndex]['date'];
    _loadBookedSeats();
  }

  @override
  void dispose() {
    // BUG 2 fix: Unlock all selected seats
    // when screen is disposed (back pressed)
    _unlockAllSelectedSeats();
    super.dispose();
  }

  // Unlock all seats user had selected
  // Called on back press or dispose
  Future<void> _unlockAllSelectedSeats() async {
    if (_selected.isEmpty) return;
    for (final seat in _selected) {
      await _unlockSeat(seat);
    }
  }

  void _generateDates() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];
    _dates = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        'day': days[date.weekday % 7],
        'month': months[date.month - 1],
        'date_num': date.day.toString(),
        'date': '${date.year}-${date.month}-${date.day}',
      };
    });
  }

  String get _timingDocId =>
      '${widget.movie.id}_${widget.cinemaId}_${_selectedDate}_$_selectedTime';

  Future<void> _loadBookedSeats() async {
    setState(() => _isLoadingSeats = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection(colTimings)
          .doc(_timingDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _booked = List<String>.from(
          data['booked'] ?? [],
        );
        final lockedData = Map<String, dynamic>.from(
          data['locked'] ?? {},
        );
        final now = DateTime.now();
        final expiredSeats = <String>[];

        lockedData.forEach((seat, lockInfo) {
          final expiresAt = (lockInfo['expiresAt'] as Timestamp).toDate();
          if (expiresAt.isBefore(now)) {
            expiredSeats.add(seat);
          }
        });

        if (expiredSeats.isNotEmpty) {
          final updates = <String, dynamic>{};
          for (final seat in expiredSeats) {
            updates['locked.$seat'] = FieldValue.delete();
          }
          await FirebaseFirestore.instance
              .collection(colTimings)
              .doc(_timingDocId)
              .update(updates);
          for (final seat in expiredSeats) {
            lockedData.remove(seat);
          }
        }

        _locked = lockedData.map(
          (key, value) => MapEntry(
            key,
            Map<String, dynamic>.from(value),
          ),
        );
      } else {
        _booked = [];
        _locked = {};
      }
    } catch (_) {
      _booked = [];
      _locked = {};
    }
    if (mounted) {
      setState(() => _isLoadingSeats = false);
    }
  }

  Future<void> _lockSeat(String seatName) async {
    final now = DateTime.now();
    final expiresAt = now.add(
      Duration(minutes: seatLockMinutes),
    );
    try {
      await FirebaseFirestore.instance
          .collection(colTimings)
          .doc(_timingDocId)
          .set({
        'locked': {
          seatName: {
            'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
            'lockedAt': Timestamp.fromDate(now),
            'expiresAt': Timestamp.fromDate(expiresAt),
          }
        }
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _unlockSeat(
    String seatName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(colTimings)
          .doc(_timingDocId)
          .update({
        'locked.$seatName': FieldValue.delete(),
      });
    } catch (_) {}
  }

  int _calculatePrice() {
    int price = 0;
    final classicRows = _seatLayout[0][0];
    final premiumRows = _seatLayout[1][0];
    for (final seat in _selected) {
      final rowNum = seat.codeUnitAt(0) - 64;
      if (rowNum <= classicRows) {
        price += seatPriceClassic;
      } else if (rowNum <= classicRows + premiumRows) {
        price += seatPricePremium;
      } else {
        price += seatPriceVip;
      }
    }
    return price;
  }

  Color _getTierColor(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return _classicColor;
      case 1:
        return _premiumColor;
      case 2:
        return _vipColor;
      default:
        return appthemecolor;
    }
  }

  String _getTierLabel(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return 'CLASSIC  •  ₹$seatPriceClassic';
      case 1:
        return 'PREMIUM  •  ₹$seatPricePremium';
      case 2:
        return 'VIP  •  ₹$seatPriceVip';
      default:
        return '';
    }
  }

  // BUG 16 fix: Check if showtime is in past
  bool _isTimePast(int timeIndex) {
    final now = DateTime.now();
    final isToday = _dateIndex == 0;
    if (!isToday) return false;

    final timeStr = _showTimes[timeIndex];
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts[1] == 'PM';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    final showTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    return showTime.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    // BUG 10 fix: PopScope replaces WillPopScope
    // BUG 2 fix: Unlock seats on back press
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await _unlockAllSelectedSeats();
        }
      },
      child: Scaffold(
        backgroundColor: mobileBackgroundColor,
        // AppAppBar replaces custom AppBar
        appBar: AppAppBar(
          title: widget.movie.title,
          subtitle: widget.theatreName,
          showBackButton: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: R.maxWidth,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildScreen(),
                        // AppLoader replaces CPI
                        if (_isLoadingSeats)
                          Padding(
                            padding: EdgeInsets.all(
                              R.px(40),
                            ),
                            child: AppLoader(),
                          )
                        else
                          _buildSeatGrid(),
                        const SeatLegend(),
                        _buildDateSelector(),
                        const Gap(12),
                        _buildTimeSelector(),
                        const Gap(20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        12,
        R.horizontalPadding,
        0,
      ),
      child: Column(
        children: [
          Text(
            'ALL EYES THIS WAY',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(10),
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Gap(8),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomPaint(
              painter: CinemaScreenPainter(),
            ),
          ),
          Text(
            'S C R E E N',
            style: TextStyle(
              color: appthemecolor,
              fontSize: R.sp(9),
              letterSpacing: 6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    int rowOffset = 0;
    return Column(
      children: List.generate(
        _seatLayout.length,
        (tierIndex) {
          final rows = _seatLayout[tierIndex][0];
          final cols = _seatLayout[tierIndex][1];
          final tierColor = _getTierColor(tierIndex);
          final currentOffset = rowOffset;
          rowOffset += rows;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: R.px(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: tierColor.withValues(alpha: 0.3),
                      ),
                    ),
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _getTierLabel(tierIndex),
                        style: TextStyle(
                          color: tierColor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: tierColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(rows, (row) {
                final rowIndex = currentOffset + row;
                final rowLabel = String.fromCharCode(65 + rowIndex);
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: R.px(3),
                    horizontal: R.horizontalPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          rowLabel,
                          style: TextStyle(
                            color: tierColor.withValues(alpha: 0.6),
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Gap(4),
                      ...List.generate(
                        cols ~/ 2,
                        (col) {
                          final seatName = '$rowLabel${col + 1}';
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: R.px(2),
                            ),
                            child: SeatWidget(
                              seatName: seatName,
                              state: _getSeatState(
                                seatName,
                              ),
                              tierColor: tierColor,
                              onTap: () => _toggleSeat(seatName),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: R.px(16)),
                      ...List.generate(
                        cols - cols ~/ 2,
                        (col) {
                          final seatNum = cols ~/ 2 + col + 1;
                          final seatName = '$rowLabel$seatNum';
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: R.px(2),
                            ),
                            child: SeatWidget(
                              seatName: seatName,
                              state: _getSeatState(
                                seatName,
                              ),
                              tierColor: tierColor,
                              onTap: () => _toggleSeat(seatName),
                            ),
                          );
                        },
                      ),
                      const Gap(4),
                      SizedBox(
                        width: 20,
                        child: Text(
                          rowLabel,
                          style: TextStyle(
                            color: tierColor.withValues(alpha: 0.6),
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Gap(8),
            ],
          );
        },
      ),
    );
  }

  SeatState _getSeatState(String seatName) {
    if (_booked.contains(seatName)) {
      return SeatState.booked;
    }
    if (_locked.containsKey(seatName)) {
      return SeatState.locked;
    }
    if (_selected.contains(seatName)) {
      return SeatState.selected;
    }
    return SeatState.available;
  }

  Future<void> _toggleSeat(
    String seatName,
  ) async {
    if (_selected.contains(seatName)) {
      setState(() => _selected.remove(seatName));
      await _unlockSeat(seatName);
    } else {
      setState(() => _selected.add(seatName));
      await _lockSeat(seatName);
    }
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SectionHeader replaces custom row
          const SectionHeader(title: 'Select Date'),
          const Gap(12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              itemBuilder: (_, index) {
                final isSelected = _dateIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _dateIndex = index;
                      _selectedDate = _dates[index]['date'];
                      _selected = [];
                    });
                    _loadBookedSeats();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    margin: const EdgeInsets.only(
                      right: 10,
                    ),
                    width: 58,
                    decoration: BoxDecoration(
                      color: isSelected ? appthemecolor : surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? appthemecolor
                            : appthemecolor.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: appthemecolor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dates[index]['day'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.6)
                                : secondaryColor,
                            fontSize: R.sp(9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          _dates[index]['date_num'],
                          style: TextStyle(
                            color: isSelected ? Colors.black : primaryColor,
                            fontSize: R.sp(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _dates[index]['month'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.6)
                                : secondaryColor,
                            fontSize: R.sp(9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SectionHeader replaces custom row
          const SectionHeader(title: 'Select Time'),
          const Gap(12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              _showTimes.length,
              (index) {
                final isSelected = _timeIndex == index;
                // BUG 16 fix: disable past times
                final isPast = _isTimePast(index);
                return GestureDetector(
                  onTap: isPast
                      ? null
                      : () async {
                          if (_timeIndex != index) {
                            // Unlock current seats
                            await _unlockAllSelectedSeats();
                            setState(() {
                              _timeIndex = index;
                              _selectedTime = _showTimes[index];
                              _selected = [];
                            });
                            await _loadBookedSeats();
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isPast
                          ? surfaceColor.withValues(alpha: 0.5)
                          : isSelected
                              ? appthemecolor.withValues(alpha: 0.15)
                              : surfaceColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isPast
                            ? appthemecolor.withValues(alpha: 0.1)
                            : isSelected
                                ? appthemecolor
                                : appthemecolor.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected && !isPast
                          ? [
                              BoxShadow(
                                color: appthemecolor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _showTimes[index],
                      style: TextStyle(
                        color: isPast
                            ? secondaryColor.withValues(alpha: 0.3)
                            : isSelected
                                ? appthemecolor
                                : secondaryColor,
                        fontSize: R.sp(12),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        decoration: isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final price = _calculatePrice();
    final hasSeats = _selected.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: appthemecolor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        12,
        R.horizontalPadding,
        R.isPhone ? 24 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSeats) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selected
                    .map(
                      (seat) => Container(
                        margin: const EdgeInsets.only(
                          right: 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appthemecolor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          seat,
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Gap(10),
          ],
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasSeats
                        ? '${_selected.length} seat${_selected.length > 1 ? "s" : ""} selected'
                        : 'Select seats to continue',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(11),
                    ),
                  ),
                  if (hasSeats) ...[
                    const Gap(2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$price',
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(28),
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const Spacer(),
              // AppButton replaces GestureDetector
              // + AnimatedContainer
              // BUG 48 fix: isLoading prevents
              // double tap
              SizedBox(
                width: 140,
                child: AppButton(
                  label: 'Proceed',
                  icon: Icons.arrow_forward_rounded,
                  height: 50,
                  isLoading: _isProceedLoading,
                  onTap: hasSeats
                      ? () async {
                          if (_isProceedLoading) return;
                          setState(
                            () => _isProceedLoading = true,
                          );

                          final bookingProvider = Provider.of<BookingProvider>(
                            context,
                            listen: false,
                          );
                          bookingProvider.setSeats(
                            _selected,
                          );
                          bookingProvider.setDate(
                            _selectedDate,
                          );
                          bookingProvider.setTime(
                            _selectedTime,
                          );
                          bookingProvider.setTimingDocId(
                            _timingDocId,
                          );

                          await Navigator.push(
                            context,
                            AppRoutes.slideUpRoute(
                              PassengerDetailsScreen(
                                movie: widget.movie,
                                amount: price,
                                seats: _selected,
                                date: _selectedDate,
                                time: _selectedTime,
                                theatreName: widget.theatreName,
                                theatreAddress: widget.theatreAddress,
                                theatreIcon: widget.theatreLogo,
                                cinemaId: widget.cinemaId,
                                timingDocId: _timingDocId,
                              ),
                            ),
                          );

                          if (mounted) {
                            setState(
                              () => _isProceedLoading = false,
                            );
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 400.ms);
  }
}
