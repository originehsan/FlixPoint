import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(
          'My Tickets',
          style: TextStyle(
            color: appthemecolor,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(colBookings)
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: appthemecolor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.movie_filter,
                    color: appthemecolor,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tickets yet',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your first movie ticket!',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data =
                  bookings[index].data() as Map<String, dynamic>;
              return _buildTicketCard(context, data, index);
            },
          );
        },
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUpcoming
                ? appthemecolor.withValues(alpha: 0.5)
                : appthemecolor.withValues(alpha: 0.1),
            width: isUpcoming ? 1 : 0.5,
          ),
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
                    height: 120.h,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      height: 120.h,
                      color: surfaceColor2,
                      child: const Icon(
                        Icons.movie,
                        color: appthemecolor,
                        size: 40,
                      ),
                    ),
                  ),
                  Container(
                    height: 120.h,
                    decoration: const BoxDecoration(
                      gradient: heroGradient,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? successColor.withValues(alpha: 0.9)
                            : surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUpcoming ? 'Upcoming' : 'Past',
                        style: TextStyle(
                          color: isUpcoming
                              ? Colors.white
                              : secondaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      booking['movieName'] ?? '',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
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
                  30,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _detail(
                          Icons.location_on,
                          'Cinema',
                          booking['cinemaName'] ?? '',
                        ),
                      ),
                      Expanded(
                        child: _detail(
                          Icons.calendar_today,
                          'Date',
                          booking['date'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _detail(
                          Icons.access_time,
                          'Time',
                          booking['time'] ?? '',
                        ),
                      ),
                      Expanded(
                        child: _detail(
                          Icons.event_seat,
                          'Seats',
                          List<String>.from(
                            booking['seats'] ?? [],
                          ).join(', '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _detail(
                        Icons.confirmation_num,
                        'Order ID',
                        '#${booking['orderId'] ?? ''}',
                      ),
                      Text(
                        '₹${booking['amount'] ?? 0}',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View ticket button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: appthemecolor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: appthemecolor.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code,
                      color: appthemecolor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'View Ticket & QR Code',
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
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
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}