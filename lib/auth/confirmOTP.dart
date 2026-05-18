import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movieticket/auth/registration.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:pinput/pinput.dart';

class ConfirmOTP extends StatefulWidget {
  final String phonenumber;
  final String verificationId;

  const ConfirmOTP({
    super.key,
    required this.phonenumber,
    required this.verificationId,
  });

  @override
  State<ConfirmOTP> createState() => _ConfirmOTPState();
}

class _ConfirmOTPState extends State<ConfirmOTP> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_pinController.text.length < 6) {
      showSnackBar('Please enter complete OTP', context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _pinController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        AppRoutes.authRoute(
          const RegistrationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showSnackBar('Invalid OTP. Please try again.', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final defaultPinTheme = PinTheme(
      width: R.isPhone ? 48 : 60,
      height: R.isPhone ? 56 : 68,
      textStyle: TextStyle(
        fontSize: R.sp(20),
        color: primaryColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: appthemecolor,
              size: 16,
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: R.hp(6)),

                // Logo centered
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appthemecolor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appthemecolor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SvgPicture.asset(
                      'assets/appicon.svg',
                      height: R.isPhone ? 40 : 55,
                    ),
                  ),
                ),

                SizedBox(height: R.px(24)),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [appthemecolor, goldLight],
                  ).createShader(bounds),
                  child: Text(
                    'Verify OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(28),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                SizedBox(height: R.px(8)),

                Text(
                  'Enter the 6-digit code sent to',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(14),
                  ),
                ),

                SizedBox(height: R.px(4)),

                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: appthemecolor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+91 ${widget.phonenumber}',
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: R.sp(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: R.px(36)),

                // OTP input
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _pinController,
                    focusNode: _focusNode,
                    defaultPinTheme: defaultPinTheme,
                    separatorBuilder: (index) => const SizedBox(width: 8),
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                          color: appthemecolor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        color: appthemecolor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: appthemecolor,
                        ),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: errorColor),
                      ),
                    ),
                    onCompleted: (pin) => _verifyOTP(),
                  ),
                ),

                SizedBox(height: R.px(16)),

                // Resend OTP
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: appthemecolor,
                        fontSize: R.sp(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: R.px(32)),

                // Verify button
                GestureDetector(
                  onTap: _isLoading ? null : _verifyOTP,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [appthemecolor, goldDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: appthemecolor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          )
                        : Text(
                            'Verify OTP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: R.sp(16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: R.px(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
