import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/utils/booking_utils.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/dashed_divider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState
    extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'My Tickets',
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(20),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.15),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: appthemecolor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: secondaryColor,
              labelStyle: TextStyle(
                fontSize: R.sp(12),
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: R.sp(12),
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Expired'),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(colBookings)
                .where('userId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: appthemecolor,
                  ),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final all = snapshot.data!.docs
                  .map((d) => d.data() as Map<String, dynamic>)
                  .toList();

              final upcoming = all.where((b) {
                final status = BookingUtils.getStatus(
                  b['date'] ?? '',
                  b['time'] ?? '',
                );
                return status == BookingStatus.upcoming ||
                    status == BookingStatus.today;
              }).toList();

              final expired = all.where((b) {
                final status = BookingUtils.getStatus(
                  b['date'] ?? '',
                  b['time'] ?? '',
                );
                return status == BookingStatus.expired;
              }).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(context, all),
                  upcoming.isEmpty
                      ? _buildEmptyState(
                          message: 'No upcoming bookings',
                          sub: 'Book a movie to see it here',
                        )
                      : _buildList(context, upcoming),
                  expired.isEmpty
                      ? _buildEmptyState(
                          message: 'No expired tickets',
                          sub: 'Past shows will appear here',
                        )
                      : _buildList(context, expired),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> bookings,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        16,
        R.horizontalPadding,
        30,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(
          context,
          bookings[index],
          index,
        );
      },
    );
  }
// to  handle exception
  Widget _buildEmptyState({
    String message = 'No tickets yet',
    String sub = 'Book your first movie ticket!',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appthemecolor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.confirmation_num_rounded,
              color: appthemecolor,
              size: 52,
            ),
          ),
          const Gap(20),
          Text(
            message,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(20),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            sub,
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Map<String, dynamic> booking,
    int index,
  ) {
    final bookingDate = booking['date'] ?? '';
    final bookingTime = booking['time'] ?? '';
    final status = BookingUtils.getStatus(
      bookingDate,
      bookingTime,
    );
    final statusColor = BookingUtils.getStatusColor(status);
    final statusLabel = BookingUtils.getStatusLabel(status);
    final statusIcon = BookingUtils.getStatusIcon(status);
    final isExpired = status == BookingStatus.expired;
    final isToday = status == BookingStatus.today;
    final remaining = BookingUtils.timeRemaining(
      bookingDate,
      bookingTime,
    );

    // Build seat passengers map
    final seatPassengers =
        Map<String, String>.from(
      booking['seatPassengers'] ?? {},
    );

    return Opacity(
      opacity: isExpired ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: () {
          final movie = TmdbMovie(
            id: booking['movieId'] ?? 0,
            title: booking['movieName'] ?? '',
            overview: '',
            posterPath: null,
            backdropPath: null,
            voteAverage: 0,
            releaseDate: '',
            genreIds: [],
          );
          Navigator.push(
            context,
            AppRoutes.scaleRoute(
              TicketScreen(
                bookingId: booking['bookingId'] ?? '',
                movie: movie,
                seats: List<String>.from(
                  booking['seats'] ?? [],
                ),
                theatreName: booking['cinemaName'] ?? '',
                theatreAddress:
                    booking['cinemaAddress'] ?? '',
                theatreIcon: '',
                date: bookingDate,
                time: bookingTime,
                amount: booking['amount'] ?? 0,
                orderId: booking['orderId'] ?? '',
                seatPassengers: seatPassengers,
                passengerEmail:
                    booking['passengerEmail'] ?? '',
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpired
                  ? appthemecolor.withValues(alpha: 0.08)
                  : isToday
                      ? const Color(0xFF00D4FF)
                          .withValues(alpha: 0.5)
                      : appthemecolor.withValues(alpha: 0.4),
              width: isExpired ? 0.5 : 1.5,
            ),
            boxShadow: isExpired
                ? null
                : [
                    BoxShadow(
                      color: isToday
                          ? const Color(0xFF00D4FF)
                              .withValues(alpha: 0.15)
                          : appthemecolor
                              .withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Movie banner
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: booking['moviePoster'] ?? '',
                      width: double.infinity,
                      height: R.isPhone ? 120 : 150,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(
                        height: R.isPhone ? 120 : 150,
                        color: surfaceColor2,
                        child: const Icon(
                          Icons.movie,
                          color: appthemecolor,
                          size: 40,
                        ),
                      ),
                    ),
                    Container(
                      height: R.isPhone ? 120 : 150,
                      decoration: const BoxDecoration(
                        gradient: heroGradient,
                      ),
                    ),

                    // Status badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor
                                .withValues(alpha: 0.4),
                          ),
                          boxShadow: isExpired
                              ? null
                              : [
                                  BoxShadow(
                                    color: statusColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 11,
                            ),
                            const Gap(4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: R.sp(10),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Movie title
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 80,
                      child: Text(
                        booking['movieName'] ?? '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(16),
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const DashedDivider(),

              // Ticket details
              Padding(
                padding: EdgeInsets.all(R.px(14)),
                child: Column(
                  children: [
                    // Cinema name - prominent
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: appthemecolor
                            .withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: appthemecolor
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.theaters_rounded,
                            color: appthemecolor,
                            size: 14,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              booking['cinemaName'] ?? '',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: R.sp(12),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    Row(
                      children: [
                        Expanded(
                          child: _detail(
                            Icons.calendar_today_rounded,
                            'Date',
                            bookingDate,
                          ),
                        ),
                        Expanded(
                          child: _detail(
                            Icons.access_time_rounded,
                            'Time',
                            bookingTime,
                          ),
                        ),
                      ],
                    ),

                    const Gap(10),

                    Row(
                      children: [
                        Expanded(
                          child: _detail(
                            Icons.event_seat_rounded,
                            'Seats',
                            List<String>.from(
                              booking['seats'] ?? [],
                            ).join(', '),
                          ),
                        ),
                        Expanded(
                          child: _detail(
                            Icons.currency_rupee_rounded,
                            'Amount',
                            '₹${booking['amount'] ?? 0}',
                          ),
                        ),
                      ],
                    ),

                    // Passengers
                    if (seatPassengers.isNotEmpty) ...[
                      const Gap(10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: surfaceColor2,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: seatPassengers.entries
                              .map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: appthemecolor
                                              .withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(4),
                                        ),
                                        child: Text(
                                          e.key,
                                          style: TextStyle(
                                            color: appthemecolor,
                                            fontSize: R.sp(9),
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Gap(8),
                                      const Icon(
                                        Icons
                                            .arrow_forward_rounded,
                                        color: secondaryColor,
                                        size: 10,
                                      ),
                                      const Gap(8),
                                      Text(
                                        e.value,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: R.sp(11),
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    const Gap(12),

                    // Time remaining or expired banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: statusColor
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 14,
                          ),
                          const Gap(8),
                          Text(
                            isExpired
                                ? 'Show has ended'
                                : isToday
                                    ? 'Show today — $remaining'
                                    : 'Show $remaining',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: R.sp(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    // View ticket button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isExpired
                            ? null
                            : LinearGradient(
                                colors: [
                                  appthemecolor
                                      .withValues(alpha: 0.15),
                                  appthemecolor
                                      .withValues(alpha: 0.05),
                                ],
                              ),
                        color: isExpired
                            ? surfaceColor2
                            : null,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpired
                              ? appthemecolor
                                  .withValues(alpha: 0.1)
                              : appthemecolor
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_rounded,
                            color: isExpired
                                ? secondaryColor
                                : appthemecolor,
                            size: 16,
                          ),
                          const Gap(8),
                          Text(
                            isExpired
                                ? 'View Expired Ticket'
                                : 'View Ticket & QR Code',
                            style: TextStyle(
                              color: isExpired
                                  ? secondaryColor
                                  : appthemecolor,
                              fontSize: R.sp(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: index * 80),
            ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: appthemecolor, size: 11),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
        const Gap(3),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(12),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}