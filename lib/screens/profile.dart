import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/watchlist_screen.dart';
import 'package:movieticket/utils/booking_utils.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/app_card.dart';
import 'package:movieticket/widgets/common/confirm_dialog.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';
import 'package:movieticket/widgets/common/gold_divider.dart';

import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout(
    UserProvider userProvider,
  ) async {
    await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of FlixPoint?',
      confirmText: 'Sign Out',
      confirmColor: errorColor,
      icon: Icons.logout_rounded,
      iconColor: errorColor,
      onConfirm: () async {
        if (mounted) {
          setState(() => _isLoggingOut = true);
        }
        userProvider.clearUser();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            AppRoutes.homeEntryRoute(const LoginIn()),
          );
        }
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [appthemecolor, goldLight],
                ).createShader(bounds),
                child: Text(
                  'FlixPoint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: R.sp(32),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Gap(4),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(12),
                ),
              ),
              const Gap(16),
              AppCard(
                backgroundColor: appthemecolor.withValues(alpha: 0.06),
                borderColor: appthemecolor.withValues(alpha: 0.15),
                child: Text(
                  'FlixPoint is a premium movie booking '
                  'app. Book tickets, manage your watchlist '
                  'and enjoy the best cinema experience.',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(12),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.code_rounded,
                    color: appthemecolor,
                    size: 14,
                  ),
                  const Gap(6),
                  Text(
                    'Built with Flutter',
                    style: TextStyle(
                      color: appthemecolor,
                      fontSize: R.sp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(20),
              AppButton(
                label: 'Close',
                height: 46,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final userProvider = Provider.of<UserProvider>(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userProvider.isLoading) {
      return Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            R.horizontalPadding,
            60,
            R.horizontalPadding,
            0,
          ),
          children: [
            ShimmerBox(
              width: double.infinity,
              height: 120,
              borderRadius: 24,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            ShimmerBox(
              width: double.infinity,
              height: 100,
              borderRadius: 16,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: 16,
            ),
          ],
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
              SliverAppBar(
                backgroundColor: mobileBackgroundColor,
                floating: true,
                snap: true,
                elevation: 0,
                automaticallyImplyLeading: false,
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
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildUserCard(userProvider),
                    Gap(R.px(20)),
                    _buildStats(uid),
                    Gap(R.px(20)),
                    _buildAccountSection(),
                    Gap(R.px(24)),
                    _buildLogoutButton(userProvider),
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

  Widget _buildUserCard(UserProvider userProvider) {
    return AppCard(
      borderRadius: 24,
      hasGlow: true,
      margin: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        8,
        R.horizontalPadding,
        0,
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
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryColor, appthemecolor],
                  ).createShader(bounds),
                  child: Text(
                    userProvider.name.isEmpty ? 'User' : userProvider.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Gap(6),
                if (userProvider.email.isNotEmpty)
                  _ProfileDetail(
                    icon: Icons.email_rounded,
                    text: userProvider.email,
                  ),
                if (userProvider.city.isNotEmpty) ...[
                  const Gap(4),
                  _ProfileDetail(
                    icon: Icons.location_on_rounded,
                    text: userProvider.city,
                  ),
                ],
                const Gap(10),
                // AppBadge replaces custom Container badge
                AppBadge(
                  label: 'FlixPoint Member',
                  icon: Icons.stars_rounded,
                  color: appthemecolor,
                  hasGlow: true,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: -0.1,
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
              _StatCard(
                label: 'Total',
                value: total.toString(),
                icon: Icons.confirmation_num_rounded,
                color: appthemecolor,
              ),
              Gap(R.px(10)),
              _StatCard(
                label: 'Upcoming',
                value: upcoming.toString(),
                icon: Icons.event_available_rounded,
                color: successColor,
              ),
              Gap(R.px(10)),
              _StatCard(
                label: 'Expired',
                value: expired.toString(),
                icon: Icons.event_busy_rounded,
                color: secondaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.bookmark_rounded,
                  title: 'My Watchlist',
                  subtitle: 'Movies you want to watch',
                  onTap: () => Navigator.push(
                    context,
                    AppRoutes.slideUpRoute(
                      const WatchlistScreen(),
                    ),
                  ),
                ),
                GoldDivider(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                ),
                _AccountTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact us',
                  onTap: () => AppSnackbar.info(
                    context,
                    'Help & Support coming soon!',
                  ),
                ),
                GoldDivider(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                ),
                _AccountTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About FlixPoint',
                  subtitle: 'Version 1.0.0',
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildLogoutButton(
    UserProvider userProvider,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: AppButton(
        label: 'Sign Out',
        icon: Icons.logout_rounded,
        isGradient: false,
        isOutlined: true,
        color: errorColor,
        height: 54,
        isLoading: _isLoggingOut,
        onTap: () => _handleLogout(userProvider),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// Profile detail row used inside user card
class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileDetail({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Row(
      children: [
        Icon(
          icon,
          color: appthemecolor,
          size: R.sp(13),
        ),
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
}

// Stat card used 3 times in stats section
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Expanded(
      child: AppCard(
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: R.sp(18),
              ),
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
}

// Account menu tile used 3 times
class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
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
}
