import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class AppAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return AppBar(
      backgroundColor:
          backgroundColor ?? mobileBackgroundColor,
      elevation: 0,
      leading: showBackButton
          ? GestureDetector(
              onTap: onBackPressed ??
                  () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appthemecolor
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: appthemecolor,
                  size: 16,
                ),
              ),
            )
          : null,
      title: subtitle != null
          ? Column(
              children: [
                _goldTitle(title),
                const Gap(2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(11),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : _goldTitle(title),
      centerTitle: true,
      actions: actions,
    );
  }

  Widget _goldTitle(String text) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          const LinearGradient(
        colors: [appthemecolor, goldLight],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: R.sp(20),
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}