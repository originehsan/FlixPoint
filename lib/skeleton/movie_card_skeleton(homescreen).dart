import "package:flutter/material.dart";
import "package:movieticket/utils/responsive.dart";

class SkeletonMovieCard extends StatelessWidget {
  const SkeletonMovieCard({super.key});

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                height: R.movieCardHeight,
                width: R.movieCardWidth,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        Container(
          width: R.movieCardWidth * 0.9,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          width: R.movieCardWidth * 0.5,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: R.movieCardWidth * 0.4,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
            )
          ],
        )
      ],
    );
  }
}
