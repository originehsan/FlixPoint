import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/booking_utils.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showLogoutDialog(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: appthemecolor.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: errorColor,
                  size: 32,
                ),
              ),
              const Gap(16),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(20),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(8),
              Text(
                'Are you sure you want to sign out of FlixPoint?',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(13),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color: appthemecolor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: appthemecolor,
                            fontSize: R.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: errorColor
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color: errorColor
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            color: errorColor,
                            fontSize: R.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      userProvider.clearUser();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          AppRoutes.homeEntryRoute(const LoginIn()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final userProvider = Provider.of<UserProvider>(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userProvider.isLoading) {
      return const Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: appthemecolor,
          ),
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
              // AppBar
              SliverAppBar(
                backgroundColor: mobileBackgroundColor,
                floating: true,
                snap: true,
                elevation: 0,
                title: ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
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
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // User card
                    _buildUserCard(context, userProvider),

                    Gap(R.px(20)),

                    // Stats
                    _buildStats(uid),

                    Gap(R.px(20)),

                    // Account section
                    _buildAccountSection(context),

                    Gap(R.px(24)),

                    // Logout button
                    _buildLogoutButton(
                      context,
                      userProvider,
                    ),

                    Gap(R.px(40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        8,
        R.horizontalPadding,
        0,
      ),
      padding: EdgeInsets.all(R.px(20)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: R.isPhone ? 72 : 90,
            height: R.isPhone ? 72 : 90,
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
                  color: appthemecolor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              userProvider.initials,
              style: TextStyle(
                color: appthemecolor,
                fontSize: R.sp(26),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Gap(R.px(16)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                    colors: [primaryColor, appthemecolor],
                  ).createShader(bounds),
                  child: Text(
                    userProvider.name.isEmpty
                        ? 'User'
                        : userProvider.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Gap(6),

                if (userProvider.email.isNotEmpty)
                  _profileDetail(
                    Icons.email_rounded,
                    userProvider.email,
                  ),

                if (userProvider.city.isNotEmpty) ...[
                  const Gap(4),
                  _profileDetail(
                    Icons.location_on_rounded,
                    userProvider.city,
                  ),
                ],

                const Gap(10),

                // FlixPoint Member badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [appthemecolor, goldDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.black,
                        size: 12,
                      ),
                      const Gap(4),
                      Text(
                        'FlixPoint Member',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: R.sp(10),
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _profileDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(13)),
        const Gap(6),
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
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;

        final upcoming = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = BookingUtils.getStatus(
            data['date'] ?? '',
            data['time'] ?? '',
          );
          return status == BookingStatus.upcoming ||
              status == BookingStatus.today;
        }).length;

        final expired = total - upcoming;

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
              Gap(R.px(10)),
              _statCard(
                'Upcoming',
                upcoming.toString(),
                Icons.event_available_rounded,
                successColor,
              ),
              Gap(R.px(10)),
              _statCard(
                'Expired',
                expired.toString(),
                Icons.event_busy_rounded,
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
            Gap(R.px(8)),
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

  Widget _buildAccountSection(BuildContext context) {
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
                'Account',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(15),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(12),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _accountTile(
                  Icons.confirmation_num_rounded,
                  'My Tickets',
                  'View all bookings',
                  onTap: () {},
                ),
                Divider(
                  color: appthemecolor.withValues(alpha: 0.08),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _accountTile(
                  Icons.help_outline_rounded,
                  'Help & Support',
                  'FAQs and contact us',
                  onTap: () {},
                ),
                Divider(
                  color: appthemecolor.withValues(alpha: 0.08),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _accountTile(
                  Icons.info_outline_rounded,
                  'About FlixPoint',
                  'Version 1.0.0',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _accountTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appthemecolor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: appthemecolor,
                size: R.sp(16),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: secondaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, userProvider),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: errorColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: errorColor.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: errorColor,
                size: 20,
              ),
              const Gap(10),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: errorColor,
                  fontSize: R.sp(15),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}