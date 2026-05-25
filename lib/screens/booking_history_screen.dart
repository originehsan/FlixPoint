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
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/appbar/app_appbar.dart';
import 'package:movieticket/widgets/common/cards/app_card.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/ticket/dashed_divider.dart';
import 'package:movieticket/widgets/ticket/ticket_detail_widget.dart';

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

  // BUG 12 fix: use local state + get()
  // instead of real-time snapshots()
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // One-time fetch — no persistent listener
  Future<void> _loadBookings() async {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore
          .instance
          .collection(colBookings)
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _allBookings = snapshot.docs
              .map(
                (d) =>
                    d.data() as Map<String, dynamic>,
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openTicket(
    Map<String, dynamic> booking,
  ) {
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
          theatreName:
              booking['cinemaName'] ?? '',
          theatreAddress:
              booking['cinemaAddress'] ?? '',
          theatreIcon: '',
          date: booking['date'] ?? '',
          time: booking['time'] ?? '',
          amount: booking['amount'] ?? 0,
          orderId: booking['orderId'] ?? '',
          seatPassengers: Map<String, String>.from(
            booking['seatPassengers'] ?? {},
          ),
          passengerEmail:
              booking['passengerEmail'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppAppBar(
        title: 'My Tickets',
        showBackButton: false,
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: appthemecolor
                    .withValues(alpha: 0.15),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: appthemecolor,
                borderRadius:
                    BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: appthemecolor
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              indicatorSize:
                  TabBarIndicatorSize.tab,
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
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: R.maxWidth,
                ),
                child: _isLoading
                    ? _buildShimmer()
                    : _allBookings.isEmpty
                        ? const EmptyState(
                            icon: Icons
                                .confirmation_num_rounded,
                            title: 'No tickets yet',
                            subtitle:
                                'Book your first movie ticket!',
                          )
                        : _buildTabView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    final upcoming = _allBookings.where((b) {
      final s = BookingUtils.getStatus(
        b['date'] ?? '',
        b['time'] ?? '',
      );
      return s == BookingStatus.upcoming ||
          s == BookingStatus.today;
    }).toList();

    final expired = _allBookings.where((b) {
      final s = BookingUtils.getStatus(
        b['date'] ?? '',
        b['time'] ?? '',
      );
      return s == BookingStatus.expired;
    }).toList();

    return RefreshIndicator(
      color: appthemecolor,
      backgroundColor: surfaceColor,
      onRefresh: _loadBookings,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_allBookings),
          upcoming.isEmpty
              ? const EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No upcoming bookings',
                  subtitle:
                      'Book a movie to see it here',
                )
              : _buildList(upcoming),
          expired.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No expired tickets',
                  subtitle:
                      'Past shows will appear here',
                )
              : _buildList(expired),
        ],
      ),
    );
  }

  Widget _buildList(
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
      itemBuilder: (context, index) =>
          _BookingCard(
        booking: bookings[index],
        index: index,
        onTap: () => _openTicket(bookings[index]),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        16,
        R.horizontalPadding,
        30,
      ),
      itemCount: 3,
      itemBuilder: (_, __) => Column(
        children: [
          ShimmerBox(
            width: double.infinity,
            height: R.isPhone ? 120 : 150,
            borderRadius: 20,
          ),
          ShimmerBox(
            width: double.infinity,
            height: 160,
            borderRadius: 0,
            margin: EdgeInsets.zero,
          ),
          ShimmerBox(
            width: double.infinity,
            height: 44,
            borderRadius: 12,
            margin: const EdgeInsets.only(
              bottom: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final int index;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final bookingDate = booking['date'] ?? '';
    final bookingTime = booking['time'] ?? '';
    final status = BookingUtils.getStatus(
      bookingDate,
      bookingTime,
    );
    final statusColor =
        BookingUtils.getStatusColor(status);
    final statusLabel =
        BookingUtils.getStatusLabel(status);
    final statusIcon =
        BookingUtils.getStatusIcon(status);
    final isExpired =
        status == BookingStatus.expired;
    final isToday = status == BookingStatus.today;
    final remaining = BookingUtils.timeRemaining(
      bookingDate,
      bookingTime,
    );
    final seatPassengers =
        Map<String, String>.from(
      booking['seatPassengers'] ?? {},
    );

    return Opacity(
      opacity: isExpired ? 0.6 : 1.0,
      child: AppCard(
        onTap: onTap,
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.zero,
        hasShadow: !isExpired,
        hasGlow: isToday,
        borderColor: isExpired
            ? appthemecolor.withValues(alpha: 0.08)
            : isToday
                ? const Color(0xFF00D4FF)
                    .withValues(alpha: 0.5)
                : appthemecolor
                    .withValues(alpha: 0.4),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        booking['moviePoster'] ?? '',
                    width: double.infinity,
                    height: R.isPhone ? 120 : 150,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ShimmerBox(
                      width: double.infinity,
                      height: R.isPhone ? 120 : 150,
                      borderRadius: 0,
                    ),
                    errorWidget: (_, __, ___) =>
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
                  // AppBadge replaces status
                  // badge Container
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AppBadge(
                      label: statusLabel,
                      icon: statusIcon,
                      color: statusColor,
                      hasGlow: !isExpired,
                    ),
                  ),
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

            Padding(
              padding: EdgeInsets.all(R.px(14)),
              child: Column(
                children: [
                  // AppCard replaces cinema Container
                  AppCard(
                    backgroundColor: appthemecolor
                        .withValues(alpha: 0.06),
                    borderColor: appthemecolor
                        .withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
                              fontWeight:
                                  FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(12),

                  Row(
                    children: [
                      Expanded(
                        child: TicketDetailWidget(
                          icon: Icons
                              .calendar_today_rounded,
                          label: 'Date',
                          value: bookingDate,
                        ),
                      ),
                      Expanded(
                        child: TicketDetailWidget(
                          icon:
                              Icons.access_time_rounded,
                          label: 'Time',
                          value: bookingTime,
                        ),
                      ),
                    ],
                  ),

                  const Gap(10),

                  Row(
                    children: [
                      Expanded(
                        child: TicketDetailWidget(
                          icon:
                              Icons.event_seat_rounded,
                          label: 'Seats',
                          value: List<String>.from(
                            booking['seats'] ?? [],
                          ).join(', '),
                        ),
                      ),
                      Expanded(
                        child: TicketDetailWidget(
                          icon: Icons
                              .currency_rupee_rounded,
                          label: 'Amount',
                          value:
                              '₹${booking['amount'] ?? 0}',
                        ),
                      ),
                    ],
                  ),

                  if (seatPassengers.isNotEmpty) ...[
                    const Gap(10),
                    AppCard(
                      backgroundColor: surfaceColor2,
                      padding:
                          const EdgeInsets.all(10),
                      child: Column(
                        children: seatPassengers
                            .entries
                            .map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets
                                        .only(bottom: 4),
                                child: Row(
                                  children: [
                                    // AppBadge for
                                    // seat number
                                    AppBadge(
                                      label: e.key,
                                      color: appthemecolor
                                          .withValues(
                                              alpha:
                                                  0.15),
                                      textColor:
                                          appthemecolor,
                                      hasGlow: false,
                                    ),
                                    const Gap(8),
                                    const Icon(
                                      Icons
                                          .arrow_forward_rounded,
                                      color:
                                          secondaryColor,
                                      size: 10,
                                    ),
                                    const Gap(8),
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        color:
                                            primaryColor,
                                        fontSize:
                                            R.sp(11),
                                        fontWeight:
                                            FontWeight
                                                .w600,
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
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(12),

                  AppButton(
                    label: isExpired
                        ? 'View Expired Ticket'
                        : 'View Ticket & QR Code',
                    icon: Icons.qr_code_rounded,
                    isGradient: !isExpired,
                    isOutlined: isExpired,
                    color: isExpired
                        ? secondaryColor
                        : null,
                    height: 44,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
            delay: Duration(
              milliseconds: index * 80,
            ),
          ),
    );
  }
}