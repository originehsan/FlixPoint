import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final userProvider = Provider.of<UserProvider>(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userProvider.isLoading) {
      return const Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: appthemecolor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context, userProvider),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildUserCard(context, userProvider),
                    SizedBox(height: R.px(20)),
                    _buildStats(uid),
                    SizedBox(height: R.px(20)),
                    _buildSectionTitle(),
                    const SizedBox(height: 12),
                    _buildBookingHistory(context, uid),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [appthemecolor, goldLight],
        ).createShader(bounds),
        child: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: R.sp(20),
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () async {
            userProvider.clearUser();
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const StartScreen(),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: errorColor,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        R.horizontalPadding, 8,
        R.horizontalPadding, 0,
      ),
      padding: EdgeInsets.all(R.px(20)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: R.isPhone ? 70 : 90,
            height: R.isPhone ? 70 : 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  appthemecolor.withValues(alpha: 0.3),
                  appthemecolor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: appthemecolor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              userProvider.initials,
              style: TextStyle(
                color: appthemecolor,
                fontSize: R.sp(24),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: R.px(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.name.isEmpty
                      ? 'User'
                      : userProvider.name,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: R.sp(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (userProvider.email.isNotEmpty)
                  _profileDetail(
                    Icons.email_rounded,
                    userProvider.email,
                  ),
                const SizedBox(height: 4),
                if (userProvider.city.isNotEmpty)
                  _profileDetail(
                    Icons.location_on_rounded,
                    userProvider.city,
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _profileDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(12),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(String uid) {
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
          padding: EdgeInsets.symmetric(
            horizontal: R.horizontalPadding,
          ),
          child: Row(
            children: [
              _statCard(
                'Total',
                total.toString(),
                Icons.confirmation_num_rounded,
                appthemecolor,
              ),
              SizedBox(width: R.px(10)),
              _statCard(
                'Upcoming',
                upcoming.toString(),
                Icons.event_rounded,
                successColor,
              ),
              SizedBox(width: R.px(10)),
              _statCard(
                'Past',
                past.toString(),
                Icons.history_rounded,
                secondaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(R.px(14)),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: R.sp(18)),
            ),
            SizedBox(height: R.px(8)),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: R.sp(22),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.horizontalPadding),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: appthemecolor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: appthemecolor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Booking History',
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistory(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(colBookings)
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(
                color: appthemecolor,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: appthemecolor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      color: appthemecolor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your first movie ticket!',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: R.horizontalPadding,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data()
                as Map<String, dynamic>;
            return _buildBookingCard(context, data, index);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(
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
          boxShadow: isUpcoming
              ? [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
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
                width: R.isPhone ? 80 : 100,
                height: R.isPhone ? 110 : 130,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: R.isPhone ? 80 : 100,
                  height: R.isPhone ? 110 : 130,
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
                              fontSize: R.sp(14),
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
                            border: Border.all(
                              color: isUpcoming
                                  ? successColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            isUpcoming ? 'Upcoming' : 'Past',
                            style: TextStyle(
                              color: isUpcoming
                                  ? successColor
                                  : secondaryColor,
                              fontSize: R.sp(9),
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
                      '${booking['date']} \u2022 ${booking['time']}',
                    ),
                    const SizedBox(height: 3),
                    _bookingDetail(
                      Icons.event_seat,
                      List<String>.from(booking['seats'] ?? [])
                          .join(', '),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\u20B9',
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${booking['amount']}',
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ).animate().fadeIn(
            delay: Duration(milliseconds: index * 100),
          ),
    );
  }

  Widget _bookingDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(12)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(11),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}