import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/widgets/cinema/cinema_screen_painter.dart';
import 'package:movieticket/widgets/cinema/seat_legend.dart';
import 'package:movieticket/widgets/cinema/seat_widget.dart';
import 'package:provider/provider.dart';
import 'package:movieticket/screens/passenger_details_screen.dart';

class SeatSelection extends StatefulWidget {
  final TmdbMovie movie;
  final String theatreName;
  final String theatreAddress;
  final String theatreLogo;
  final String cinemaId;

  const SeatSelection({
    super.key,
    required this.movie,
    required this.theatreName,
    required this.theatreAddress,
    required this.theatreLogo,
    required this.cinemaId, required String preSelectedTime,
  });

  @override
  State<SeatSelection> createState() => _SeatSelectionState();
}

class _SeatSelectionState extends State<SeatSelection> {
  // Seat layout: [rows, cols]
  // Order: Classic → Premium → VIP (front to back)
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

  final List<String> _showTimes = [
    '10:00 AM',
    '1:00 PM',
    '4:00 PM',
    '7:00 PM',
    '10:00 PM',
  ];

  late List<Map<String, dynamic>> _dates;

  // Tier colors
  static const Color _classicColor = Color(0xFF1E3A8A);
  static const Color _premiumColor = Color(0xFF6D28D9);
  static const Color _vipColor = Color(0xFFC9A84C);

  @override
  void initState() {
    super.initState();
    _generateDates();
    _selectedTime = _showTimes[_timeIndex];
    _selectedDate = _dates[_dateIndex]['date'];
    _loadBookedSeats();
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
      'Dec'
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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
        _booked = List<String>.from(data['booked'] ?? []);
        final lockedData = Map<String, dynamic>.from(data['locked'] ?? {});
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
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      } else {
        _booked = [];
        _locked = {};
      }
    } catch (e) {
      _booked = [];
      _locked = {};
    }
    if (mounted) setState(() => _isLoadingSeats = false);
  }

  Future<void> _lockSeat(String seatName) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: seatLockMinutes));
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
    } catch (e) {
      // Silent
    }
  }

  Future<void> _unlockSeat(String seatName) async {
    try {
      await FirebaseFirestore.instance
          .collection(colTimings)
          .doc(_timingDocId)
          .update({'locked.$seatName': FieldValue.delete()});
    } catch (e) {
      // Silent
    }
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

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: appthemecolor,
              size: 16,
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.movie.title,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(14),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.theatreName,
              style: TextStyle(
                color: appthemecolor,
                fontSize: R.sp(11),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: R.maxWidth),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Cinema screen
                      _buildScreen(),

                      // Seat grid
                      if (_isLoadingSeats)
                        Padding(
                          padding: EdgeInsets.all(R.px(40)),
                          child: const CircularProgressIndicator(
                            color: appthemecolor,
                          ),
                        )
                      else
                        _buildSeatGrid(),

                      // Legend
                      const SeatLegend(),

                      // Date selector
                      _buildDateSelector(),

                      const Gap(12),

                      // Time selector
                      _buildTimeSelector(),

                      const Gap(20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky bottom bar
          _buildBottomBar(),
        ],
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
      children: List.generate(_seatLayout.length, (tierIndex) {
        final rows = _seatLayout[tierIndex][0];
        final cols = _seatLayout[tierIndex][1];
        final tierColor = _getTierColor(tierIndex);
        final currentOffset = rowOffset;
        rowOffset += rows;

        return Column(
          children: [
            // Tier label
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

            // Seat rows
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
                    // Row label
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

                    // Left seats
                    ...List.generate(cols ~/ 2, (col) {
                      final seatName = '$rowLabel${col + 1}';
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.px(2),
                        ),
                        child: SeatWidget(
                          seatName: seatName,
                          state: _getSeatState(seatName),
                          tierColor: tierColor,
                          onTap: () => _toggleSeat(seatName),
                        ),
                      );
                    }),

                    // Aisle
                    SizedBox(width: R.px(16)),

                    // Right seats
                    ...List.generate(cols - cols ~/ 2, (col) {
                      final seatNum = cols ~/ 2 + col + 1;
                      final seatName = '$rowLabel$seatNum';
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.px(2),
                        ),
                        child: SeatWidget(
                          seatName: seatName,
                          state: _getSeatState(seatName),
                          tierColor: tierColor,
                          onTap: () => _toggleSeat(seatName),
                        ),
                      );
                    }),

                    const Gap(4),

                    // Row label right
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
      }),
    );
  }

  SeatState _getSeatState(String seatName) {
    if (_booked.contains(seatName)) return SeatState.booked;
    if (_locked.containsKey(seatName)) return SeatState.locked;
    if (_selected.contains(seatName)) return SeatState.selected;
    return SeatState.available;
  }

  Future<void> _toggleSeat(String seatName) async {
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
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: appthemecolor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(8),
              Text(
                'Select Date',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(15),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 10),
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
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: appthemecolor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(8),
              Text(
                'Select Time',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(15),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_showTimes.length, (index) {
              final isSelected = _timeIndex == index;
              return GestureDetector(
                onTap: () async {
                  if (_timeIndex != index) {
                    setState(() {
                      _timeIndex = index;
                      _selectedTime = _showTimes[index];
                      _selected = [];
                    });
                    await _loadBookedSeats();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? appthemecolor.withValues(alpha: 0.15)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? appthemecolor
                          : appthemecolor.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
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
                      color: isSelected ? appthemecolor : secondaryColor,
                      fontSize: R.sp(12),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
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
          // Selected seats chips
          if (hasSeats) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selected
                    .map(
                      (seat) => Container(
                        margin: const EdgeInsets.only(right: 6),
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
              // Price
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

              // Proceed button
              GestureDetector(
                onTap: hasSeats
                    ? () {
                        final bookingProvider = Provider.of<BookingProvider>(
                          context,
                          listen: false,
                        );
                        bookingProvider.setSeats(_selected);
                        bookingProvider.setDate(_selectedDate);
                        bookingProvider.setTime(_selectedTime);
                        bookingProvider.setTimingDocId(_timingDocId);

                        Navigator.push(
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
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: hasSeats
                        ? const LinearGradient(
                            colors: [appthemecolor, goldDark],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: hasSeats ? null : surfaceColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: hasSeats
                          ? appthemecolor
                          : appthemecolor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: hasSeats
                        ? [
                            BoxShadow(
                              color: appthemecolor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Proceed',
                        style: TextStyle(
                          color: hasSeats
                              ? Colors.black
                              : appthemecolor.withValues(alpha: 0.4),
                          fontSize: R.sp(14),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (hasSeats) ...[
                        const Gap(6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 400.ms);
  }
}
