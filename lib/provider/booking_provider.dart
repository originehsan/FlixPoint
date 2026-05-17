import 'package:flutter/material.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/utils/constants.dart';

class BookingProvider extends ChangeNotifier {
  // Selected movie
  TmdbMovie? _selectedMovie;

  // Selected cinema
  String _cinemaId = '';
  String _cinemaName = '';
  String _cinemaAddress = '';
  String _cinemaLogo = '';

  // Selected seats
  List<String> _selectedSeats = [];

  // Selected date & time
  String _selectedDate = '';
  String _selectedTime = '';

  // Timing doc id
  String _timingDocId = '';

  // Getters
  TmdbMovie? get selectedMovie => _selectedMovie;
  String get cinemaId => _cinemaId;
  String get cinemaName => _cinemaName;
  String get cinemaAddress => _cinemaAddress;
  String get cinemaLogo => _cinemaLogo;
  List<String> get selectedSeats => _selectedSeats;
  String get selectedDate => _selectedDate;
  String get selectedTime => _selectedTime;
  String get timingDocId => _timingDocId;

  // Check if cinema selected
  bool get hasCinema => _cinemaId.isNotEmpty;

  // Check if seats selected
  bool get hasSeats => _selectedSeats.isNotEmpty;

  // Calculate total price
  int get totalPrice {
    int total = 0;
    for (final seat in _selectedSeats) {
      final prefix = seat[0];
      if (['A', 'B', 'C', 'D'].contains(prefix)) {
        total += seatPriceClassic;
      } else if (['E', 'F', 'G'].contains(prefix)) {
        total += seatPricePremium;
      } else {
        total += seatPriceVip;
      }
    }
    return total;
  }

  // Set selected movie
  void setMovie(TmdbMovie movie) {
    _selectedMovie = movie;
    // Reset cinema and seats when movie changes
    _cinemaId = '';
    _cinemaName = '';
    _cinemaAddress = '';
    _cinemaLogo = '';
    _selectedSeats = [];
    _selectedDate = '';
    _selectedTime = '';
    _timingDocId = '';
    notifyListeners();
  }

  // Set selected cinema
  void setCinema({
    required String cinemaId,
    required String cinemaName,
    required String cinemaAddress,
    required String cinemaLogo,
  }) {
    _cinemaId = cinemaId;
    _cinemaName = cinemaName;
    _cinemaAddress = cinemaAddress;
    _cinemaLogo = cinemaLogo;
    // Reset seats when cinema changes
    _selectedSeats = [];
    _selectedDate = '';
    _selectedTime = '';
    _timingDocId = '';
    notifyListeners();
  }

  // Set selected seats
  void setSeats(List<String> seats) {
    _selectedSeats = seats;
    notifyListeners();
  }

  // Add seat
  void addSeat(String seat) {
    if (!_selectedSeats.contains(seat)) {
      _selectedSeats.add(seat);
      notifyListeners();
    }
  }

  // Remove seat
  void removeSeat(String seat) {
    _selectedSeats.remove(seat);
    notifyListeners();
  }

  // Toggle seat
  void toggleSeat(String seat) {
    if (_selectedSeats.contains(seat)) {
      removeSeat(seat);
    } else {
      addSeat(seat);
    }
  }

  // Set date
  void setDate(String date) {
    _selectedDate = date;
    // Reset seats when date changes
    _selectedSeats = [];
    _timingDocId = '';
    notifyListeners();
  }

  // Set time
  void setTime(String time) {
    _selectedTime = time;
    // Reset seats when time changes
    _selectedSeats = [];
    _timingDocId = '';
    notifyListeners();
  }

  // Set timing doc id
  void setTimingDocId(String docId) {
    _timingDocId = docId;
    notifyListeners();
  }

  // Clear entire booking
  void clearBooking() {
    _selectedMovie = null;
    _cinemaId = '';
    _cinemaName = '';
    _cinemaAddress = '';
    _cinemaLogo = '';
    _selectedSeats = [];
    _selectedDate = '';
    _selectedTime = '';
    _timingDocId = '';
    notifyListeners();
  }
}