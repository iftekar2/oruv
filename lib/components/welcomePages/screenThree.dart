import 'package:flutter/material.dart';

class ScreenThree extends StatelessWidget {
  const ScreenThree({super.key});

  static const Color bgColor = Color(0xFFF1BE41);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Image.asset(
          "lib/components/welcomePages/images/ob-focus.jpg",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
