import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieticket/models/registration.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> signUpUser({
    required String email,
    required String name,
    required String password,
    String city = '',
  }) async {
    String res = 'An error occurred';
    try {
      final cred =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserDetails(
        email: email,
        name: name,
        city: city,
      );

      await _firestore
          .collection('Users')
          .doc(cred.user!.uid)
          .set(user.toJson());

      res = 'success';
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'email-already-in-use':
          res =
              'This email is already registered. Please sign in.';
          break;
        case 'weak-password':
          res =
              'Password must be at least 6 characters.';
          break;
        case 'invalid-email':
          res = 'Please enter a valid email address.';
          break;
        case 'network-request-failed':
          res =
              'No internet connection. Please try again.';
          break;
        default:
          res = error.message ?? 'An error occurred.';
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> loginuser({
    required String email,
    required String password,
  }) async {
    String res = 'An error occurred';
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Please enter all fields.';
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      res = 'success';
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          res = 'Invalid email or password.';
          break;
        case 'user-disabled':
          res =
              'This account has been disabled. Contact support.';
          break;
        case 'too-many-requests':
          res =
              'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          res =
              'No internet connection. Please try again.';
          break;
        case 'invalid-email':
          res = 'Please enter a valid email address.';
          break;
        default:
          res = error.message ?? 'An error occurred.';
      }
    } catch (error) {
      res = error.toString();
    }
    return res;
  }
}