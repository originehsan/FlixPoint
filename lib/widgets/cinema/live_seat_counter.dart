import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';

class LiveSeatCounter extends StatelessWidget {
  final int movieId;

  const LiveSeatCounter({
    super.key,
    required this.movieId,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 8,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(colTimings)
            .snapshots(),
        builder: (context, snapshot) {
          int totalBooked = 0;
          const totalSeats = 108;

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              if (doc.id.startsWith('${movieId}_')) {
                final data =
                    doc.data() as Map<String, dynamic>;
                final booked = List<String>.from(
                  data['booked'] ?? [],
                );
                totalBooked += booked.length;
              }
            }
          }

          final available = totalSeats - totalBooked;
          final percentage = available / totalSeats;

          Color seatColor;
          String seatText;
          if (available > 60) {
            seatColor = successColor;
            seatText = 'Good availability';
          } else if (available > 20) {
            seatColor = warningColor;
            seatText = 'Filling fast!';
          } else {
            seatColor = errorColor;
            seatText = 'Almost full!';
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seatColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      color: seatColor,
                      size: R.sp(18),
                    ),
                    const Gap(8),
                    Text(
                      '$available seats available today',
                      style: TextStyle(
                        color: seatColor,
                        fontSize: R.sp(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: seatColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: seatColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        seatText,
                        style: TextStyle(
                          color: seatColor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor:
                        seatColor.withValues(alpha: 0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(seatColor),
                    minHeight: 6,
                  ),
                ),
                const Gap(6),
                Text(
                  '$totalBooked of $totalSeats seats booked',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(11),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}