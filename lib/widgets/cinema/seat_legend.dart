import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(
            const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            const Color(0xFF1E3A8A).withValues(alpha: 0.5),
            'Available',
          ),
          _legendItem(
            appthemecolor,
            appthemecolor,
            'Selected',
          ),
          _legendItem(
            const Color(0xFF1A0A0A),
            const Color(0xFF3A1A1A),
            'Booked',
            icon: Icons.close_rounded,
          ),
          _legendItem(
            const Color(0xFF2A2A2A),
            const Color(0xFF444444),
            'Locked',
            icon: Icons.lock_rounded,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    Color color,
    Color borderColor,
    String label, {
    IconData? icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 10, color: borderColor)
              : null,
        ),
        const Gap(5),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(9),
          ),
        ),
      ],
    );
  }
}