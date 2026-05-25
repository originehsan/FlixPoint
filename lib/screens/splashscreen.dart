import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_loader.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  late AnimationController _letterController;
  late AnimationController _grainController;
  late AnimationController _fadeController;

  String _name = 'User';
  String _typewriterText = '';
  final String _fullTagline = 'Book. Watch. Enjoy.';
  Timer? _typewriterTimer;
  int _revealedLetters = 0;
  bool _showTagline = false;
  bool _showGrain = false;
  final String _logoText = 'FLIXPOINT';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );

    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _grainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() => _showGrain = true);
    _scanController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _letterController.forward();
    _startLetterReveal();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    setState(() => _showTagline = true);
    _startTypewriter();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    _navigate();
  }

  void _startLetterReveal() {
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_revealedLetters >= _logoText.length) {
        timer.cancel();
        return;
      }
      setState(() => _revealedLetters++);
    });
  }

  void _startTypewriter() {
    int index = 0;
    _typewriterTimer = Timer.periodic(
      const Duration(milliseconds: 60),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (index >= _fullTagline.length) {
          timer.cancel();
          return;
        }
        setState(() {
          _typewriterText = _fullTagline.substring(0, index + 1);
          index++;
        });
      },
    );
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRoutes.fadeRoute(OpeningScreen(name: _name)),
    );
  }

  Future<void> _initialize() async {
    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    await userProvider.initialize();
    if (mounted) {
      setState(() {
        _name = userProvider.name.isNotEmpty ? userProvider.name : 'User';
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _letterController.dispose();
    _grainController.dispose();
    _fadeController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _scanController,
          _letterController,
          _grainController,
        ]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Film grain background
              if (_showGrain)
                CustomPaint(
                  painter: FilmGrainPainter(_grainController.value),
                ),

              // Scan line
              if (_scanController.value > 0 && _scanController.value < 1)
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * _scanAnimation.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          appthemecolor.withValues(alpha: 0.8),
                          Colors.white,
                          appthemecolor.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: appthemecolor.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _logoText.length,
                        (index) {
                          final isRevealed = index < _revealedLetters;
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isRevealed ? 1.0 : 0.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              transform: Matrix4.translationValues(
                                0,
                                isRevealed ? 0 : 20,
                                0,
                              ),
                              child: Text(
                                _logoText[index],
                                style: TextStyle(
                                  color: isRevealed
                                      ? appthemecolor
                                      : Colors.transparent,
                                  fontSize: R.sp(42),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  shadows: isRevealed
                                      ? [
                                          Shadow(
                                            color: appthemecolor.withValues(
                                                alpha: 0.8),
                                            blurRadius: 20,
                                          ),
                                          Shadow(
                                            color: goldLight.withValues(
                                                alpha: 0.4),
                                            blurRadius: 40,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width:
                          _revealedLetters >= _logoText.length ? R.wp(55) : 0,
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            appthemecolor,
                            goldLight,
                            appthemecolor,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_showTagline)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _typewriterText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: R.sp(14),
                              letterSpacing: 3,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _grainController,
                            builder: (context, child) {
                              return Opacity(
                                opacity:
                                    (_grainController.value * 10).floor().isEven
                                        ? 1.0
                                        : 0.0,
                                child: Container(
                                  width: 2,
                                  height: R.sp(14),
                                  color: appthemecolor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Projector light effect
              if (_scanController.value > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height *
                        _scanAnimation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appthemecolor.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class FilmGrainPainter extends CustomPainter {
  final double animationValue;
  final Random _random = Random();

  FilmGrainPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1;

    final grainCount = (size.width * size.height / 800).toInt();
    for (int i = 0; i < grainCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(FilmGrainPainter oldDelegate) => true;
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
              // User logged in → go to home
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
            return const Scaffold(
              backgroundColor: mobileBackgroundColor,
              body: Center(
                child: AppLoader(),
              ),
            );
          }
          // User not logged in → go to SignIn directly
          return const LoginIn();
        },
      ),
    );
  }
}
