import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movieticket/utils/constants.dart';

class UserProvider extends ChangeNotifier {
  String _uid = '';
  String _name = '';
  String _email = '';
  String _city = '';
  bool _isLoggedIn = false;
  bool _isLoading = false;

  String get uid => _uid;
  String get name => _name;
  String get email => _email;
  String get city => _city;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  String get initials {
    if (_name.isEmpty) return 'U';
    final parts = _name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name
        .substring(0, _name.length < 2 ? _name.length : 2)
        .toUpperCase();
  }

  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      _isLoggedIn = true;
      await fetchUserData();
    } else {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserData() async {
    if (_uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection(colUsers)
          .doc(_uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['username'] ?? '';
        _email = data['email'] ?? '';
        _city = data['city'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUser(String uid) async {
    _uid = uid;
    _isLoggedIn = true;
    await fetchUserData();
  }

  void clearUser() {
    _uid = '';
    _name = '';
    _email = '';
    _city = '';
    _isLoggedIn = false;
    notifyListeners();
  }
}