import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movieticket/methods/authfunctions.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/navbar.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/widgets/text_field.dart';
import 'package:provider/provider.dart';

class LoginIn extends StatefulWidget {
  const LoginIn({super.key});

  @override
  State<LoginIn> createState() => _LoginInState();
}

class _LoginInState extends State<LoginIn> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showSnackBar('Please fill all fields', context);
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

      // Use UID not email
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await userProvider.setUser(uid);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        AppRoutes.homeEntryRoute(Navbar(name: userProvider.name)),
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
            'Sign In',
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

                // App name
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
                  'Welcome back!',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(14),
                  ),
                ),

                SizedBox(height: R.px(40)),

                // Email field
                TextFieldInput(
                  textEditingController: _emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress,
                ),

                SizedBox(height: R.px(16)),

                // Password field
                TextFieldInput(
                  textEditingController: _passwordController,
                  hintText: 'Enter your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                ),

                SizedBox(height: R.px(30)),

                // Sign in button
                GestureDetector(
                  onTap: _isLoading ? null : _loginUser,
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
                            'Sign In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
