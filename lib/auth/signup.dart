import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movieticket/auth/confirmOTP.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException ex) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ex.message ?? 'Verification failed',
                style: const TextStyle(color: primaryColor),
              ),
              backgroundColor: errorColor,
            ),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            AppRoutes.authRoute(
              ConfirmOTP(
                phonenumber: _phoneController.text.trim(),
                verificationId: verificationId,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(20),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            child: Column(
              children: [
                SizedBox(height: R.hp(8)),

                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appthemecolor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/appicon.svg',
                    height: R.isPhone ? 50 : 70,
                  ),
                ),

                SizedBox(height: R.px(16)),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [appthemecolor, goldLight],
                  ).createShader(bounds),
                  child: Text(
                    'FlixPoint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(28),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                SizedBox(height: R.px(8)),

                Text(
                  'Enter your phone number to get started',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(13),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: R.px(40)),

                // Phone field label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(height: R.px(8)),

                // Phone input
                Form(
                  key: _formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: appthemecolor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: appthemecolor.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            '+91',
                            style: TextStyle(
                              color: appthemecolor,
                              fontSize: R.sp(15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: R.sp(15),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter 10 digit number',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: R.sp(14),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.length != 10) {
                                return 'Enter valid 10 digit number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: R.px(30)),

                // Send OTP button
                GestureDetector(
                  onTap: _isLoading ? null : _sendOTP,
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
                            'Send OTP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: R.sp(16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: R.hp(8)),

                // Terms
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: TextStyle(
                    color: hintColor,
                    fontSize: R.sp(11),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
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
