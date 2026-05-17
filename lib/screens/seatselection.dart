import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/payment.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';

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
  // Seat layout: [rows, cols] for each tier
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

  // Hardcoded show times
  final List<String> _showTimes = [
    '10:00 AM',
    '1:00 PM',
    '4:00 PM',
    '7:00 PM',
    '10:00 PM',
  ];

  // Dynamic dates (next 7 days)
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

        // Get permanently booked seats
        _booked = List<String>.from(data['booked'] ?? []);

        // Get locked seats and release expired ones
        final lockedData = Map<String, dynamic>.from(data['locked'] ?? {});
        final now = DateTime.now();
        final expiredSeats = <String>[];

        lockedData.forEach((seat, lockInfo) {
          final expiresAt = (lockInfo['expiresAt'] as Timestamp).toDate();
          if (expiresAt.isBefore(now)) {
            expiredSeats.add(seat);
          }
        });

        // Release expired locks
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
    R.init(context);
    R.init(context);
    R.init(context);
    int seatNumber = -1;
    final totalLength =
        _seatLayout[0][0] + _seatLayout[1][0] + _seatLayout[2][0];

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: appthemecolor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.movie.title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.theatreName,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Screen indicator
            _buildScreenIndicator(),
            const SizedBox(height: 10),

            // Seat grid
            if (_isLoadingSeats)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: appthemecolor),
              )
            else
              SizedBox(
                height: (totalLength * 48).h,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _seatLayout.length,
                  itemBuilder: (_, tierIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          // Tier label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(tierIndex)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getTierColor(tierIndex)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _getTierLabel(tierIndex),
                              style: TextStyle(
                                color: _getTierColor(tierIndex),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Seat rows
                          ...List.generate(_seatLayout[tierIndex][0], (row) {
                            seatNumber++;
                            int c = 0;
                            return Wrap(
                              alignment: WrapAlignment.center,
                              children: List.generate(_seatLayout[tierIndex][1],
                                  (col) {
                                // Middle gap
                                if (col == _seatLayout[tierIndex][1] ~/ 2 &&
                                    c == 0) {
                                  c++;
                                  return const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: SizedBox(
                                      height: 25,
                                      width: 25,
                                    ),
                                  );
                                }
                                final seatName =
                                    '${String.fromCharCode(65 + seatNumber)}${col + 1 - c}';
                                final isBooked = _booked.contains(seatName);
                                final isLocked = _locked.containsKey(seatName);
                                final isSelected = _selected.contains(seatName);

                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
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
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: isBooked
                                            ? seatBooked
                                            : isLocked
                                                ? seatLocked
                                                : isSelected
                                                    ? appthemecolor
                                                    : seatAvailable,
                                        border: isSelected
                                            ? Border.all(
                                                color: appthemecolor,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      height: 25,
                                      width: 25,
                                      alignment: Alignment.center,
                                      child: Text(
                                        seatName,
                                        style: TextStyle(
                                          color: isBooked
                                              ? secondaryColor
                                              : isSelected
                                                  ? mobileBackgroundColor
                                                  : secondaryColor,
                                          fontSize: 7.sp,
                                          fontWeight: FontWeight.w500,
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
                              }),
                            );
                          }),
                          const Divider(
                            color: Color(0xFF2A2A2A),
                            indent: 30,
                            endIndent: 30,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Seat legend
            _buildLegend(),
            const SizedBox(height: 16),

            // Date and time selection
            _buildDateTimeSection(),
            const SizedBox(height: 16),

            // Price and book button
            if (_selected.isNotEmpty) _buildPriceSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'All eyes this way please',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: ScreenClipper(),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appthemecolor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 2,
                decoration: BoxDecoration(
                  color: appthemecolor,
                  boxShadow: [
                    BoxShadow(
                      color: appthemecolor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'SCREEN',
            style: TextStyle(
              color: appthemecolor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(seatAvailable, 'Available'),
          _legendItem(seatBooked, 'Booked'),
          _legendItem(seatLocked, 'Locked'),
          _legendItem(appthemecolor, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select Date',
            style: TextStyle(
              color: primaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: isSelected ? appthemecolor : surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? appthemecolor
                          : appthemecolor.withValues(alpha: 0.2),
                    ),
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
                          fontSize: 10.sp,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dates[index]['day'],
                        style: TextStyle(
                          color:
                              isSelected ? mobileBackgroundColor : primaryColor,
                          fontSize: 16.sp,
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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select Time',
            style: TextStyle(
              color: primaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 45.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _showTimes.length,
            itemBuilder: (_, index) {
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
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  alignment: Alignment.center,
                  child: Text(
                    _showTimes[index],
                    style: TextStyle(
                      color: isSelected ? appthemecolor : secondaryColor,
                      fontSize: 11.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final price = _calculatePrice();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
        ),
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
                    '${_selected.length} seat${_selected.length > 1 ? 's' : ''} selected',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 12.sp,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'â‚¹ $price',
                    style: TextStyle(
                      color: appthemecolor,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().scale(
                        duration: 200.ms,
                        curve: Curves.elasticOut,
                      ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (_selected.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
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
                  height: 50.h,
                  width: 140.w,
                  decoration: BoxDecoration(
                    color: appthemecolor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: mobileBackgroundColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _selected
                .map(
                  (seat) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appthemecolor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: appthemecolor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      seat,
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: 11.sp,
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
        return seatClassic;
      case 1:
        return seatPremium as Color;
      case 2:
        return seatVip;
      default:
        return appthemecolor;
    }
  }

  String _getTierLabel(int tierIndex) {
    switch (tierIndex) {
      case 0:
        return 'Classic â€¢ â‚¹$seatPriceClassic';
      case 1:
        return 'Premium â€¢ â‚¹$seatPricePremium';
      case 2:
        return 'VIP â€¢ â‚¹$seatPriceVip';
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




