import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:movieticket/widgets/text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const String keyName = "name";
  bool isloading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void signUp() async {
    // validate passwords match
    if (_passwordController.text != _confirmpasswordController.text) {
      showSnackBar("Passwords do not match", context);
      return;
    }

    // validate fields not empty
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _cityController.text.isEmpty) {
      showSnackBar("Please fill all fields", context);
      return;
    }

    setState(() {
      isloading = true;
    });

    String res = await AuthMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      city: _cityController.text,
    );

    if (!mounted) return;

    if (res == "success") {
      // save name to shared preferences
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyName, _nameController.text);

      if (!mounted) return;

      setState(() {
        isloading = false;
      });

      showSnackBar("Registered successfully", context);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Navbar(name: _nameController.text),
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
        title: const Text("Register"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                SizedBox(height: 20.h),
                TextFieldInput(
                  textEditingController: _nameController,
                  hintText: "Enter your name",
                  textInputType: TextInputType.text,
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
                  hintText: "New password",
                  textInputType: TextInputType.text,
                  isPass: true,
                ),
                SizedBox(height: 20.h),
                TextFieldInput(
                  textEditingController: _confirmpasswordController,
                  hintText: "Confirm password",
                  textInputType: TextInputType.text,
                  isPass: true,
                ),
                SizedBox(height: 20.h),
                TextFieldInput(
                  textEditingController: _cityController,
                  hintText: "Enter your City",
                  textInputType: TextInputType.text,
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: signUp,
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
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            "Register",
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
      ),
    );
  }
}