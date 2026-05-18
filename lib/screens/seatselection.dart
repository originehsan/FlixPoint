import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/screens/payment.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:provider/provider.dart';

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
    required this.cinemaId,
  });

  @override
  State<SeatSelection> createState() => _SeatSelectionState();
}

class _SeatSelectionState extends State<SeatSelection> {
  final List<List<int>> _seatLayout = [
    [4, 9], // Classic
    [3, 9], // Premium
    [5, 9], // VIP
  ];

  List<String> _selected = [];
  List<String> _booked = [];
  Map<String, Map<String, dynamic>> _locked = {};

  int _dateIndex = 2;
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
    _dates = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      final months = [
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
      return {
        'selected': index == _dateIndex,
        'month': months[date.month - 1],
        'day': date.day.toString(),
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
      // Handle silently
    }
  }

  Future<void> _unlockSeat(String seatName) async {
    try {
      await FirebaseFirestore.instance
          .collection(colTimings)
          .doc(_timingDocId)
          .update({
        'locked.$seatName': FieldValue.delete(),
      });
    } catch (e) {
      // Handle silently
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

  @override
  Widget build(BuildContext context) {
    R.init(context);
    int seatNumber = -1;
    final totalLength =
        _seatLayout[0][0] + _seatLayout[1][0] + _seatLayout[2][0];

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: appthemecolor,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.movie.title,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(15),
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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildScreenIndicator(),
                SizedBox(height: R.hp(2)),
                if (_isLoadingSeats)
                  Padding(
                    padding: EdgeInsets.all(R.px(40)),
                    child: const CircularProgressIndicator(
                      color: appthemecolor,
                    ),
                  )
                else
                  SizedBox(
                    height: totalLength * 48,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _seatLayout.length,
                      itemBuilder: (_, tierIndex) {
                        return Padding(
                          padding: EdgeInsets.only(top: R.px(10)),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: R.px(16),
                                  vertical: R.px(6),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getTierColor(tierIndex)
                                          .withValues(alpha: 0.3),
                                      _getTierColor(tierIndex)
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getTierColor(tierIndex)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _getTierLabel(tierIndex),
                                  style: TextStyle(
                                    color: _getTierColor(tierIndex),
                                    fontSize: R.sp(11),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: R.px(8)),
                              ...List.generate(
                                _seatLayout[tierIndex][0],
                                (row) {
                                  seatNumber++;
                                  int c = 0;
                                  return Wrap(
                                    alignment: WrapAlignment.center,
                                    children: List.generate(
                                      _seatLayout[tierIndex][1],
                                      (col) {
                                        if (col ==
                                                _seatLayout[tierIndex][1] ~/
                                                    2 &&
                                            c == 0) {
                                          c++;
                                          return Padding(
                                            padding: EdgeInsets.all(
                                              R.px(4),
                                            ),
                                            child: SizedBox(
                                              height: R.seatSize,
                                              width: R.seatSize,
                                            ),
                                          );
                                        }
                                        final seatName =
                                            '${String.fromCharCode(65 + seatNumber)}${col + 1 - c}';
                                        final isBooked =
                                            _booked.contains(seatName);
                                        final isLocked =
                                            _locked.containsKey(seatName);
                                        final isSelected =
                                            _selected.contains(seatName);

                                        return Padding(
                                          padding: EdgeInsets.all(
                                            R.px(4),
                                          ),
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (isBooked || isLocked) return;
                                              if (isSelected) {
                                                _selected.remove(seatName);
                                                await _unlockSeat(seatName);
                                              } else {
                                                _selected.add(seatName);
                                                await _lockSeat(seatName);
                                              }
                                              setState(() {});
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: R.seatSize,
                                              height: R.seatSize,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: isBooked
                                                    ? const Color(0xFF1A1A1A)
                                                    : isLocked
                                                        ? const Color(
                                                            0xFF555555)
                                                        : isSelected
                                                            ? appthemecolor
                                                            : _getSeatTierColor(
                                                                tierIndex),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? appthemecolor
                                                      : isBooked
                                                          ? Colors.transparent
                                                          : _getSeatTierColor(
                                                                  tierIndex)
                                                              .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                  width: isSelected ? 1.5 : 0.5,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: appthemecolor
                                                              .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                          blurRadius: 8,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                seatName,
                                                style: TextStyle(
                                                  color: isBooked
                                                      ? const Color(0xFF333333)
                                                      : isSelected
                                                          ? mobileBackgroundColor
                                                          : Colors.white
                                                              .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                  fontSize: R.seatFontSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                              .animate(
                                                target: isSelected ? 1 : 0,
                                              )
                                              .scale(
                                                begin: const Offset(1, 1),
                                                end: const Offset(1.1, 1.1),
                                                duration: 150.ms,
                                              ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: const Color(0xFF2A2A2A),
                                indent: R.px(30),
                                endIndent: R.px(30),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                _buildLegend(),
                SizedBox(height: R.hp(2)),
                _buildDateSelector(),
                SizedBox(height: R.hp(1.5)),
                _buildTimeSelector(),
                SizedBox(height: R.hp(2)),
                if (_selected.isNotEmpty) _buildPriceSection(),
                SizedBox(height: R.hp(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      child: Column(
        children: [
          Text(
            'ALL EYES THIS WAY',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(11),
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: ScreenClipper(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appthemecolor.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Container(
                width: R.wp(75),
                height: 2,
                decoration: BoxDecoration(
                  color: appthemecolor,
                  boxShadow: [
                    BoxShadow(
                      color: appthemecolor.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'SCREEN',
            style: TextStyle(
              color: appthemecolor,
              fontSize: R.sp(9),
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      padding: EdgeInsets.all(R.px(12)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(const Color(0xFF2A2A2A), 'Available'),
          _legendItem(const Color(0xFF555555), 'Locked'),
          _legendItem(const Color(0xFF1A1A1A), 'Booked'),
          _legendItem(appthemecolor, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(10),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(16),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 75,
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
                    width: 55,
                    decoration: BoxDecoration(
                      color: isSelected ? appthemecolor : surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? appthemecolor
                            : appthemecolor.withValues(alpha: 0.2),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: appthemecolor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dates[index]['month'],
                          style: TextStyle(
                            color: isSelected
                                ? mobileBackgroundColor
                                : secondaryColor,
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dates[index]['day'],
                          style: TextStyle(
                            color: isSelected
                                ? mobileBackgroundColor
                                : primaryColor,
                            fontSize: R.sp(18),
                            fontWeight: FontWeight.w700,
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time',
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(16),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              _showTimes.length,
              (index) {
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
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appthemecolor.withValues(alpha: 0.15)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? appthemecolor
                            : appthemecolor.withValues(alpha: 0.2),
                      ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final price = _calculatePrice();
    return Container(
      margin: EdgeInsets.all(R.horizontalPadding),
      padding: EdgeInsets.all(R.px(16)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selected.length} seat${_selected.length > 1 ? "s" : ""} selected',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\u20B9',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: R.sp(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' $price',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: R.sp(28),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (_selected.isEmpty) return;

                  // Update BookingProvider
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
                      PaymentScreen(
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
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.px(24),
                    vertical: R.px(14),
                  ),
                  decoration: BoxDecoration(
                    color: appthemecolor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: mobileBackgroundColor,
                      fontSize: R.sp(15),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selected
                .map(
                  (seat) => Container(
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms);
  }

  Color _getTierColor(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return const Color(0xFF1E3A8A);
      case 1:
        return const Color(0xFF6D28D9);
      case 2:
        return const Color(0xFF92400E);
      default:
        return appthemecolor;
    }
  }

  Color _getSeatTierColor(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return const Color(0xFF1E3A8A);
      case 1:
        return const Color(0xFF6D28D9);
      case 2:
        return const Color(0xFF92400E);
      default:
        return appthemecolor;
    }
  }

  String _getTierLabel(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return 'Classic \u2022 \u20B9$seatPriceClassic';
      case 1:
        return 'Premium \u2022 \u20B9$seatPricePremium';
      case 2:
        return 'VIP \u2022 \u20B9$seatPriceVip';
      default:
        return '';
    }
  }
}

class ScreenClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.1, 0);
    path.lineTo(size.width * 0.9, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
