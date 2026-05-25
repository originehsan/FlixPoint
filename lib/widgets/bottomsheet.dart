import 'package:flutter/material.dart';

Future<dynamic> bottomsheet(BuildContext context) {
  return showModalBottomSheet(
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25.0),
        topRight: Radius.circular(25),
      ),
    ),
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 25, 15, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose language",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            const Text(
              "Which language do you want to use?",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
            ListTile(
              title: const Text("English"),
              trailing: Checkbox(
                shape: const CircleBorder(
                  side: BorderSide(),
                ),
                value: true,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      );
    },
  );
}
