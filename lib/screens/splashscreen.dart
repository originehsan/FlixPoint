import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/startscreen.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showImage = false;
  String _name = 'User';

  @override
  void initState() {
    super.initState();
    _initialize();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showImage = true);
      }
    });
  }

  Future<void> _initialize() async {
    // Initialize user provider
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    await userProvider.initialize();

    if (mounted) {
      setState(() {
        _name = userProvider.name.isNotEmpty
            ? userProvider.name
            : 'User';
      });
    }

    // Navigate after 4 seconds
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

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            LottieBuilder.asset(
              'assets/animation.json',
              height: R.isPhone ? 300 : 400,
            ),
            AnimatedPositioned(
              duration: const Duration(seconds: 1),
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _showImage ? 1 : 0,
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/appicon.svg',
                      height: R.isPhone ? 40 : 60,
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                        colors: [appthemecolor, goldLight],
                      ).createShader(bounds),
                      child: Text(
                        'FlixPoint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.sp(28),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book. Watch. Enjoy.',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(13),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
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
      backgroundColor: mobileBackgroundColor,
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return Navbar(name: name);
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: errorColor),
                ),
              );
            }
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: appthemecolor,
              ),
            );
          }
          return const StartScreen();
        },
      ),
    );
  }
}