import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final bool isGradient;
  final Color? color;
  final IconData? icon;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.isGradient = true,
    this.color,
    this.icon,
    this.height = 54,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: isGradient && !isOutlined
              ? const LinearGradient(
                  colors: [appthemecolor, goldDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isOutlined
              ? Colors.transparent
              : (!isGradient ? (color ?? surfaceColor) : null),
          borderRadius: BorderRadius.circular(30),
          border: isOutlined
              ? Border.all(
                  color: color ?? appthemecolor,
                  width: 1.5,
                )
              : null,
          boxShadow: isOutlined || !isGradient
              ? null
              : [
                  BoxShadow(
                    color: appthemecolor
                        .withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: isOutlined
                      ? (color ?? appthemecolor)
                      : Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isOutlined
                          ? (color ?? appthemecolor)
                          : Colors.black,
                      size: R.sp(18),
                    ),
                    const Gap(8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isOutlined
                          ? (color ?? appthemecolor)
                          : Colors.black,
                      fontSize: R.sp(15),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}