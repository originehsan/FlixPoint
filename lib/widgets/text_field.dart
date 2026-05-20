import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';

class TextFieldInput extends StatefulWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final TextInputType textInputType;
  final IconData? prefixIcon;
  final List<String>? autofillHints;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    required this.textInputType,
    this.prefixIcon,
    this.autofillHints,
  });

  @override
  State<TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<TextFieldInput> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? appthemecolor
                : appthemecolor.withValues(alpha: 0.2),
            width: _isFocused ? 1.5 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: appthemecolor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: TextField(
          cursorColor: appthemecolor,
          controller: widget.textEditingController,
          keyboardType: widget.textInputType,
          obscureText: widget.isPass && _obscureText,
          autofillHints: widget.autofillHints,
          enableSuggestions: true,
          autocorrect: !widget.isPass,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(15),
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: R.sp(14),
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? appthemecolor : secondaryColor,
                    size: R.sp(20),
                  )
                : null,
            suffixIcon: widget.isPass
                ? GestureDetector(
                    onTap: () => setState(
                      () => _obscureText = !_obscureText,
                    ),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: secondaryColor,
                      size: R.sp(20),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}