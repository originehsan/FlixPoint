import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            R.horizontalPadding,
            16,
            R.horizontalPadding,
            10,
          ),
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
                  color: appthemecolor
                      .withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const Gap(10),
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (subtitle != null) ...[
            const Gap(8),
            Text(
              subtitle!,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(11),
              ),
            ),
          ],
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: appthemecolor
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: appthemecolor
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: appthemecolor,
                    fontSize: R.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}