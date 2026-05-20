import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';

class FlixPointLogo extends StatefulWidget {
  final bool animate;
  final double fontSize;
  final bool showTagline;
  final String tagline;

  const FlixPointLogo({
    super.key,
    this.animate = true,
    this.fontSize = 36,
    this.showTagline = false,
    this.tagline = 'Cinema at your fingertips',
  });

  @override
  State<FlixPointLogo> createState() => _FlixPointLogoState();
}

class _FlixPointLogoState extends State<FlixPointLogo>
    with TickerProviderStateMixin {
  final String _text = 'FLIXPOINT';
  int _revealedLetters = 0;
  bool _showUnderline = false;
  bool _showTagline = false;
  Timer? _letterTimer;

  late AnimationController _underlineController;
  late Animation<double> _underlineAnimation;
  late AnimationController _taglineController;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();

    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _underlineAnimation = CurvedAnimation(
      parent: _underlineController,
      curve: Curves.easeOut,
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    if (widget.animate) {
      _startAnimation();
    } else {
      setState(() {
        _revealedLetters = _text.length;
        _showUnderline = true;
        _showTagline = true;
      });
      _underlineController.forward();
      _taglineController.forward();
    }
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _letterTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_revealedLetters >= _text.length) {
          timer.cancel();
          _showUnderlineAndTagline();
          return;
        }
        setState(() => _revealedLetters++);
      },
    );
  }

  void _showUnderlineAndTagline() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showUnderline = true);
    _underlineController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showTagline = true);
    _taglineController.forward();
  }

  @override
  void dispose() {
    _letterTimer?.cancel();
    _underlineController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated letters
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _text.length,
            (index) {
              final isRevealed = index < _revealedLetters;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isRevealed ? 1.0 : 0.0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: isRevealed ? Offset.zero : const Offset(0, 0.3),
                  curve: Curves.easeOutBack,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [appthemecolor, goldLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      _text[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: isRevealed
                            ? [
                                Shadow(
                                  color: appthemecolor.withValues(alpha: 0.6),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Animated underline
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _underlineAnimation,
          builder: (context, child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _showUnderline ? _underlineAnimation.value : 0,
                child: Container(
                  height: 2,
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
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Tagline
        if (widget.showTagline) ...[
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _taglineAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _showTagline ? _taglineAnimation.value : 0,
                child: Text(
                  widget.tagline,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: widget.fontSize * 0.35,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
