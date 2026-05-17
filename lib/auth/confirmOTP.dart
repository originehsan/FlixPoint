import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/auth/registration.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/pickimage.dart';
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
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  bool _isloading = false;
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void verifyOTP() async {
    if (pinController.text.length < 6) {
      showSnackBar("Please enter complete OTP", context);
      return;
    }

    setState(() {
      _isloading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: pinController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        _isloading = false;
      });

      showSnackBar("OTP verified successfully", context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationScreen(),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isloading = false;
      });
      showSnackBar(err.toString(), context);
    }
  }

  Widget otpScreen() {
    const focusedBorderColor = appthemecolor;
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = appthemecolor;

    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 60.h,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(248, 248, 248, 1),
      ),
      decoration: BoxDecoration(
        color: appthemecolor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Pinput(
              length: 6,
              controller: pinController,
              focusNode: focusNode,
              defaultPinTheme: defaultPinTheme,
              separatorBuilder: (index) => const SizedBox(width: 8),
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 22,
                    height: 1,
                    color: focusedBorderColor,
                  ),
                ],
              ),
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: focusedBorderColor),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: focusedBorderColor),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyBorderWith(
                border: Border.all(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(flex: 1, child: SizedBox()),
              const Text(
                "Confirm OTP code",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: appthemecolor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Enter the OTP sent to ${widget.phonenumber}',
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 35),
                child: otpScreen(),
              ),
              const Flexible(flex: 5, child: SizedBox()),
              InkWell(
                onTap: verifyOTP,
                child: Container(
                  height: 55.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30),
                      right: Radius.circular(30),
                    ),
                    color: appthemecolor,
                  ),
                  alignment: Alignment.center,
                  child: _isloading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}