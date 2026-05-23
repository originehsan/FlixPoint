import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

enum TicketDetailLayout { column, row }

class TicketDetailWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TicketDetailLayout layout;
  final Color? valueColor; // ADD THIS

  const TicketDetailWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.layout = TicketDetailLayout.column,
    this.valueColor

  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return layout == TicketDetailLayout.column
        ? _buildColumn()
        : _buildRow();
  }

  // Column layout — used in ticket screen
  // icon + label on top, value below
  Widget _buildColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: appthemecolor,
              size: R.sp(12),
            ),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(12),
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Row layout — used in payment screen
  // icon + label on left, value on right
  Widget _buildRow() {
    return Row(
      children: [
        Icon(
          icon,
          color: appthemecolor,
          size: R.sp(14),
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            color: valueColor ?? primaryColor,
            fontSize: R.sp(13),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? primaryColor,
              fontSize: R.sp(13),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}