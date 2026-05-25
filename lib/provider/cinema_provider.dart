import 'package:flutter/material.dart';

class CinemaProvider with ChangeNotifier {
  int _cinemaIndex = -1;
  int get cinemaIndex => _cinemaIndex;

  void selectCinema(int index) {
    _cinemaIndex = index;
    notifyListeners();
  }
}