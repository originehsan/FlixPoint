import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TmdbService _tmdbService = TmdbService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc =
          await FirebaseFirestore.instance.collection(colUsers).doc(uid).get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _initials {
    final name = _userData?['username'] ?? 'User';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    R.init(context);
    R.init(context);
    R.init(context);
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: appthemecolor),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildUserCard(),
                      const SizedBox(height: 20),
                      _buildStats(),
                      const SizedBox(height: 20),
                      _buildBookingHistory(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      title: Text(
        'Profile',
        style: TextStyle(
          color: appthemecolor,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: secondaryColor),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const StartScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    final name = _userData?['username'] ?? 'User';
    final email = _userData?['email'] ?? '';
    final city = _userData?['city'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: appthemecolor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: TextStyle(
                color: appthemecolor,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        color: appthemecolor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                if (city.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: appthemecolor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(colBookings)
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        final upcoming = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = DateTime.tryParse(data['date'] ?? '');
              return date != null && date.isAfter(DateTime.now());
            }).length ??
            0;
        final past = total - upcoming;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard('Total', total.toString(), Icons.confirmation_num),
              const SizedBox(width: 10),
              _statCard('Upcoming', upcoming.toString(), Icons.event),
              const SizedBox(width: 10),
              _statCard('Past', past.toString(), Icons.history),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: appthemecolor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: appthemecolor,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildBookingHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Booking History',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
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
                  children: [
                    const SizedBox(height: 30),
                    const Icon(
                      Icons.movie_filter,
                      color: appthemecolor,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 16.sp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book your first movie ticket!',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildBookingCard(data, index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index) {
    final date = DateTime.tryParse(booking['date'] ?? '');
    final isUpcoming = date != null && date.isAfter(DateTime.now());

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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpcoming
                ? appthemecolor.withValues(alpha: 0.4)
                : appthemecolor.withValues(alpha: 0.1),
            width: isUpcoming ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: booking['moviePoster'] ?? '',
                width: 80.w,
                height: 110.h,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 80.w,
                  height: 110.h,
                  color: surfaceColor2,
                  child: const Icon(
                    Icons.movie,
                    color: appthemecolor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking['movieName'] ?? '',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? successColor.withValues(alpha: 0.15)
                                : surfaceColor2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUpcoming ? 'Upcoming' : 'Past',
                            style: TextStyle(
                              color: isUpcoming ? successColor : secondaryColor,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _bookingDetail(
                      Icons.location_on,
                      booking['cinemaName'] ?? '',
                    ),
                    const SizedBox(height: 3),
                    _bookingDetail(
                      Icons.calendar_today,
                      '${booking['date']} â€¢ ${booking['time']}',
                    ),
                    const SizedBox(height: 3),
                    _bookingDetail(
                      Icons.event_seat,
                      List<String>.from(booking['seats'] ?? []).join(', '),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'â‚¹${booking['amount']}',
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 100)),
    );
  }

  Widget _bookingDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}




