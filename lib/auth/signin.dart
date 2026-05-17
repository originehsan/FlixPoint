import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:movieticket/widgets/text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginIn extends StatefulWidget {
  const LoginIn({super.key});

  @override
  State<LoginIn> createState() => _LoginInState();
}

class _LoginInState extends State<LoginIn> {
  static const String keyName = "name";
  String name = "";
  bool isloading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    setState(() {
      isloading = true;
    });

    String res = await AuthMethods().loginuser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // mounted check after async gap
    if (!mounted) return;

    if (res == "success") {
      try {
        var usersnapshot = await FirebaseFirestore.instance
            .collection("Users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (!mounted) return;
        name = usersnapshot["username"] ?? "User";
      } catch (err) {
        if (!mounted) return;
        showSnackBar(err.toString(), context);
      }

      var prefs = await SharedPreferences.getInstance();
      prefs.setString(keyName, name);

      if (!mounted) return;
      setState(() {
        isloading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Navbar(name: name),
        ),
      );
    } else {
      setState(() {
        isloading = false;
      });
      showSnackBar(res, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text("Sign In"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const Flexible(flex: 1, child: SizedBox()),
            SvgPicture.asset(
              "assets/appicon.svg",
              height: 40.h,
            ),
            SizedBox(height: 20.h),
            TextFieldInput(
              textEditingController: _emailController,
              hintText: "Enter your mail",
              textInputType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20.h),
            TextFieldInput(
              textEditingController: _passwordController,
              hintText: "Password",
              textInputType: TextInputType.text,
              isPass: true,
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: loginUser,
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
                child: isloading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Sign in",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const Flexible(flex: 3, child: SizedBox()),
          ],
        ),
      ),
    );
  }
}