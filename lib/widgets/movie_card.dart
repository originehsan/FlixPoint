import 'package:flutter/material.dart';

class MovieCard extends StatefulWidget {
  final List<String> images;
  final int index;
  const MovieCard({super.key, required this.images, required this.index});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: Image.asset(
          widget.images[widget.index],
        ),
      ),
    );
  }
}
