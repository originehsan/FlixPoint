import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/flixpoint_logo.dart';
import 'package:movieticket/widgets/text_field.dart';
import 'package:provider/provider.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showSnackBar('Please fill all fields', context);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showSnackBar('Passwords do not match', context);
      return;
    }

    if (_passwordController.text.length < 6) {
      showSnackBar(
        'Password must be at least 6 characters',
        context,
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (res == 'success') {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await userProvider.setUser(uid);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        AppRoutes.homeEntryRoute(
          Navbar(name: userProvider.name),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      showSnackBar(res, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                Gap(R.px(24)),

                // FlixPoint animated logo
                const FlixPointLogo(
                  animate: true,
                  fontSize: 32,
                  showTagline: true,
                  tagline: 'Join us today!',
                ),

                Gap(R.px(32)),

                // Name
                _fieldLabel('What should we call you?'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController: _nameController,
                  hintText: 'Enter your name',
                  textInputType: TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.name],
                ),

                Gap(R.px(16)),

                // Email
                _fieldLabel('Email'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController: _emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  autofillHints: const [AutofillHints.email],
                ),

                Gap(R.px(16)),

                // Password
                _fieldLabel('Password'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController: _passwordController,
                  hintText: 'Create a password',
                  textInputType: TextInputType.text,
                  isPass: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [AutofillHints.newPassword],
                ),

                Gap(R.px(16)),

                // Confirm Password
                _fieldLabel('Confirm Password'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [AutofillHints.newPassword],
                ),

                Gap(R.px(32)),

                // Create account button
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor.withValues(alpha: 0.3 * value),
                            blurRadius: 20 * value,
                            spreadRadius: 2 * value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: _isLoading ? null : _signUp,
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
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            )
                          : Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: R.sp(16),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),

                Gap(R.px(24)),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        AppRoutes.authRoute(const LoginIn()),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: R.sp(13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                Gap(R.px(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: secondaryColor,
          fontSize: R.sp(12),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
