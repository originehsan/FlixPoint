import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? appthemecolor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (iconColor ?? appthemecolor)
                      .withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (iconColor ?? appthemecolor)
                        .withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? appthemecolor,
                size: 44,
              ),
            ),
            const Gap(20),
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(20),
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              subtitle,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(13),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const Gap(24),
              AppButton(
                label: actionLabel ?? 'Try Again',
                onTap: onAction,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}