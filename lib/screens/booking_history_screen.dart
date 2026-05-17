import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

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
                            color: appthemecolor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.movie_filter_rounded,
                          color: appthemecolor,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No tickets yet',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(22),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Book your first movie ticket!',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: R.sp(14),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final bookings = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(R.horizontalPadding),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final data = bookings[index].data()
                      as Map<String, dynamic>;
                  return _buildTicketCard(context, data, index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Map<String, dynamic> booking,
    int index,
  ) {
    final date = DateTime.tryParse(booking['date'] ?? '');
    final isUpcoming =
        date != null && date.isAfter(DateTime.now());

    return GestureDetector(
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
          MaterialPageRoute(
            builder: (context) => TicketScreen(
              bookingId: booking['bookingId'] ?? '',
              movie: movie,
              seats: List<String>.from(booking['seats'] ?? []),
              theatreName: booking['cinemaName'] ?? '',
              theatreAddress: booking['cinemaAddress'] ?? '',
              theatreIcon: '',
              date: booking['date'] ?? '',
              time: booking['time'] ?? '',
              amount: booking['amount'] ?? 0,
              orderId: booking['orderId'] ?? '',
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
            color: isUpcoming
                ? appthemecolor.withValues(alpha: 0.5)
                : appthemecolor.withValues(alpha: 0.1),
            width: isUpcoming ? 1.5 : 0.5,
          ),
          boxShadow: isUpcoming
              ? [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
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
                    height: R.isPhone ? 130 : 160,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(
                      height: R.isPhone ? 130 : 160,
                      color: surfaceColor2,
                      child: const Icon(
                        Icons.movie,
                        color: appthemecolor,
                        size: 40,
                      ),
                    ),
                  ),
                  Container(
                    height: R.isPhone ? 130 : 160,
                    decoration: const BoxDecoration(
                      gradient: heroGradient,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? successColor
                            : surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isUpcoming
                            ? [
                                BoxShadow(
                                  color: successColor
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUpcoming
                                ? Icons.event_available
                                : Icons.history,
                            color: isUpcoming
                                ? Colors.white
                                : secondaryColor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUpcoming ? 'Upcoming' : 'Past',
                            style: TextStyle(
                              color: isUpcoming
                                  ? Colors.white
                                  : secondaryColor,
                              fontSize: R.sp(10),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 60,
                    child: Text(
                      booking['movieName'] ?? '',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: R.sp(18),
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

            // Dashed divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  40,
                  (index) => Expanded(
                    child: Container(
                      height: 1,
                      color: index % 2 == 0
                          ? appthemecolor.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

            // Ticket details
            Padding(
              padding: EdgeInsets.all(R.px(16)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _detail(
                          Icons.location_on_rounded,
                          'Cinema',
                          booking['cinemaName'] ?? '',
                        ),
                      ),
                      Expanded(
                        child: _detail(
                          Icons.calendar_today_rounded,
                          'Date',
                          booking['date'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _detail(
                          Icons.access_time_rounded,
                          'Time',
                          booking['time'] ?? '',
                        ),
                      ),
                      Expanded(
                        child: _detail(
                          Icons.event_seat_rounded,
                          'Seats',
                          List<String>.from(
                            booking['seats'] ?? [],
                          ).join(', '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _detail(
                        Icons.confirmation_num_rounded,
                        'Order ID',
                        '#${booking['orderId'] ?? ''}',
                      ),
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
                            '${booking['amount'] ?? 0}',
                            style: TextStyle(
                              color: appthemecolor,
                              fontSize: R.sp(20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View ticket button
            Padding(
              padding: EdgeInsets.fromLTRB(
                R.px(16), 0, R.px(16), R.px(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appthemecolor.withValues(alpha: 0.15),
                      appthemecolor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appthemecolor.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_rounded,
                      color: appthemecolor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Ticket & QR Code',
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: R.sp(13),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
            delay: Duration(milliseconds: index * 100),
          ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: appthemecolor, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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