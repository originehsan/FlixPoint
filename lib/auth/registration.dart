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

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validate fields
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _cityController.text.isEmpty) {
      showSnackBar('Please fill all fields', context);
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      showSnackBar('Passwords do not match', context);
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      showSnackBar('Password must be at least 6 characters', context);
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
    );

    if (!mounted) return;

    if (res == 'success') {
      // Use UserProvider instead of SharedPreferences
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await userProvider.setUser(uid);

      if (!mounted) return;

      setState(() => _isLoading = false);

      showSnackBar('Registered successfully!', context);

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
            'Create Account',
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
                SizedBox(height: R.px(24)),

                // Logo
                Container(
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

                SizedBox(height: R.px(12)),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [appthemecolor, goldLight],
                  ).createShader(bounds),
                  child: Text(
                    'FlixPoint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: R.sp(24),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                SizedBox(height: R.px(4)),

                Text(
                  'Join us today!',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(13),
                  ),
                ),

                SizedBox(height: R.px(28)),

                // Name field
                _fieldLabel('Full Name'),
                SizedBox(height: R.px(6)),
                TextFieldInput(
                  textEditingController: _nameController,
                  hintText: 'Enter your full name',
                  textInputType: TextInputType.name,
                ),

                SizedBox(height: R.px(16)),

                // Email field
                _fieldLabel('Email'),
                SizedBox(height: R.px(6)),
                TextFieldInput(
                  textEditingController: _emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress,
                ),

                SizedBox(height: R.px(16)),

                // Password field
                _fieldLabel('Password'),
                SizedBox(height: R.px(6)),
                TextFieldInput(
                  textEditingController: _passwordController,
                  hintText: 'Create a password',
                  textInputType: TextInputType.text,
                  isPass: true,
                ),

                SizedBox(height: R.px(16)),

                // Confirm password field
                _fieldLabel('Confirm Password'),
                SizedBox(height: R.px(6)),
                TextFieldInput(
                  textEditingController: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  textInputType: TextInputType.text,
                  isPass: true,
                ),

                SizedBox(height: R.px(16)),

                // City field
                _fieldLabel('City'),
                SizedBox(height: R.px(6)),
                TextFieldInput(
                  textEditingController: _cityController,
                  hintText: 'Enter your city',
                  textInputType: TextInputType.text,
                ),

                SizedBox(height: R.px(30)),

                // Register button
                GestureDetector(
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

                SizedBox(height: R.px(30)),
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
