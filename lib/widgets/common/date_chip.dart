import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class DateChip extends StatelessWidget {
  final String day;
  final String dateNum;
  final String month;
  final bool isSelected;
  final VoidCallback onTap;

  const DateChip({
    super.key,
    required this.day,
    required this.dateNum,
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        width: 58,
        decoration: BoxDecoration(
          color: isSelected ? appthemecolor : surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? appthemecolor
                : appthemecolor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        appthemecolor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.6)
                    : secondaryColor,
                fontSize: R.sp(9),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              dateNum,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : primaryColor,
                fontSize: R.sp(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              month,
              style: TextStyle(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.6)
                    : secondaryColor,
                fontSize: R.sp(9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}