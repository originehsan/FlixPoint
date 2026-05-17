import 'dart:async';
import 'package:movieticket/utils/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/utils/color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String keyName = "name";
  bool _showImage = false;
  String _name = "User";

  @override
  void initState() {
    super.initState();
    _getName();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showImage = true;
        });
      }
    });
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OpeningScreen(name: _name),
          ),
        );
      }
    });
  }

  void _getName() async {
    var prefs = await SharedPreferences.getInstance();
    var savedName = prefs.getString(keyName);
    if (mounted) {
      setState(() {
        _name = savedName ?? "User";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: LottieBuilder.asset(
                "assets/animation.json",
                height: 300.h,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(seconds: 1),
              bottom: 0.h,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _showImage ? 1 : 0,
                child: SvgPicture.asset('assets/appicon.svg'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpeningScreen extends StatelessWidget {
  final String name;

  const OpeningScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return Navbar(name: name);
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          return const StartScreen();
        },
      ),
    );
  }
}