import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/auth/signin.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/snackbars/app_snackbar.dart';
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
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
      AppSnackbar.warning(
        context,
        'Please fill all fields',
      );
      return;
    }

    if (_passwordController.text !=
        _confirmPasswordController.text) {
      AppSnackbar.error(
        context,
        'Passwords do not match',
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      AppSnackbar.error(
        context,
        'Password must be at least 6 characters',
      );
      return;
    }

    // Basic email validation
    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      AppSnackbar.error(
        context,
        'Please enter a valid email address',
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

      // BUG 4 fix: guard empty uid
      final uid =
          FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(() => _isLoading = false);
        AppSnackbar.error(
          context,
          'Registration failed. Please try again.',
        );
        return;
      }

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
      // AppSnackbar replaces showSnackBar
      // BUG 22: friendly error messages
      // come from AuthMethods already
      AppSnackbar.error(context, res);
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
          constraints:
              BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            child: Column(
              children: [
                Gap(R.px(24)),

                const FlixPointLogo(
                  animate: true,
                  fontSize: 32,
                  showTagline: true,
                  tagline: 'Join us today!',
                ),

                Gap(R.px(32)),

                _fieldLabel(
                  'What should we call you?',
                ),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController:
                      _nameController,
                  hintText: 'Enter your name',
                  textInputType: TextInputType.name,
                  prefixIcon:
                      Icons.person_outline_rounded,
                  autofillHints: const [
                    AutofillHints.name,
                  ],
                ),

                Gap(R.px(16)),

                _fieldLabel('Email'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController:
                      _emailController,
                  hintText: 'Enter your email',
                  textInputType:
                      TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                ),

                Gap(R.px(16)),

                _fieldLabel('Password'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController:
                      _passwordController,
                  hintText: 'Create a password',
                  textInputType: TextInputType.text,
                  isPass: true,
                  prefixIcon:
                      Icons.lock_outline_rounded,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                ),

                Gap(R.px(16)),

                _fieldLabel('Confirm Password'),
                Gap(R.px(6)),
                TextFieldInput(
                  textEditingController:
                      _confirmPasswordController,
                  hintText: 'Confirm your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                  prefixIcon:
                      Icons.lock_outline_rounded,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                ),

                Gap(R.px(32)),

                // TweenAnimationBuilder for glow
                // AppButton inside for consistency
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration:
                      const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor
                                .withValues(
                              alpha: 0.3 * value,
                            ),
                            blurRadius: 20 * value,
                            spreadRadius: 2 * value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: AppButton(
                    label: 'Create Account',
                    height: 56,
                    // AppLoader.small replaces CPI
                    isLoading: _isLoading,
                    onTap: _isLoading
                        ? null
                        : _signUp,
                  ),
                ),

                Gap(R.px(24)),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacement(
                        context,
                        AppRoutes.authRoute(
                          const LoginIn(),
                        ),
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