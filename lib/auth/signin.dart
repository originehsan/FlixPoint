import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/auth/signup.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';
import 'package:movieticket/widgets/flixpoint_logo.dart';
import 'package:movieticket/widgets/text_field.dart';
import 'package:provider/provider.dart';

class LoginIn extends StatefulWidget {
  const LoginIn({super.key});

  @override
  State<LoginIn> createState() => _LoginInState();
}

class _LoginInState extends State<LoginIn> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppSnackbar.warning(
        context,
        'Please fill all fields',
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthMethods().loginuser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (res == 'success') {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );

      // BUG 4 fix: guard empty uid
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(() => _isLoading = false);
        AppSnackbar.error(
          context,
          'Login failed. Please try again.',
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
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            child: Column(
              children: [
                Gap(R.hp(6)),

                const FlixPointLogo(
                  animate: true,
                  fontSize: 36,
                  showTagline: true,
                  tagline: 'Welcome back!',
                ),

                Gap(R.px(48)),

                TextFieldInput(
                  textEditingController: _emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                ),

                Gap(R.px(16)),

                TextFieldInput(
                  textEditingController: _passwordController,
                  hintText: 'Enter your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                ),

                Gap(R.px(32)),

                // TweenAnimationBuilder kept
                // for pulsing glow effect
                // AppButton inside replaces
                // GestureDetector+Container
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
                            color: appthemecolor.withValues(
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
                    label: 'Sign In',
                    height: 56,
                    // AppLoader.small replaces CPI
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _loginUser,
                  ),
                ),

                Gap(R.px(24)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        AppRoutes.authRoute(
                          const SignUp(),
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: R.sp(13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                Gap(R.hp(6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
