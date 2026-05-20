import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieticket/models/registration.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signUpUser({
    required String email,
    required String name,
    required String password,
    String city = '',
  }) async {
    String res = "some error occurred";
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserDetails user = UserDetails(
        email: email,
        name: name,
        city: city,
      );

      await _firestore
          .collection('Users')
          .doc(cred.user!.uid)
          .set(user.toJson());

      res = "success";
    } on FirebaseAuthException catch (error) {
      if (error.code == "email-already-in-use") {
        res = "This email is already in use.";
      } else if (error.code == "weak-password") {
        res = "Password must be at least 6 characters.";
      } else {
        res = error.message ?? "An error occurred.";
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
    String res = 'some error occurred';
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all fields.";
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == "invalid-credential") {
        res = "Invalid email or password.";
      } else if (error.code == "user-not-found") {
        res = "No account found with this email.";
      } else if (error.code == "wrong-password") {
        res = "Incorrect password.";
      } else {
        res = error.message ?? "An error occurred.";
      }
    } catch (error) {
      res = error.toString();
    }
    return res;
  }
}