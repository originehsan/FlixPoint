import 'package:flutter/material.dart';
import 'package:movieticket/utils/color.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final TextInputType textInputType;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    required this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: appthemecolor,
      controller: textEditingController,
      decoration: InputDecoration(
        fillColor: greycolorshade1,
        hintText: hintText,
        border: OutlineInputBorder(
          borderSide: Divider.createBorderSide(context),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: appthemecolor,
          ),
        ),
        enabledBorder: const OutlineInputBorder(),
        hintStyle: const TextStyle(fontSize: 20),
        filled: true,
        contentPadding: const EdgeInsets.all(20),
      ),
      keyboardType: textInputType,
      obscureText: isPass,
    );
  }
}