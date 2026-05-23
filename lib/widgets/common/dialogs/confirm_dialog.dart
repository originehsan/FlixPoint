import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;
  final Color? iconColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final isDestructive = confirmColor == errorColor;

    return Dialog(
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
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? appthemecolor).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (iconColor ?? appthemecolor).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? appthemecolor,
                  size: 32,
                ),
              ),
              const Gap(16),
            ],
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(8),
            Text(
              message,
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
                  child: AppButton(
                    label: cancelText,
                    isOutlined: true,
                    isGradient: false,
                    color: appthemecolor,
                    height: 48,
                    onTap: () {
                      onCancel?.call();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: AppButton(
                    label: confirmText,
                    isOutlined: true,
                    isGradient: false,
                    color: confirmColor ?? appthemecolor,
                    height: 48,
                    onTap: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmColor: confirmColor,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}
