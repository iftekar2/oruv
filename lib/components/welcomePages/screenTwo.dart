import 'package:flutter/material.dart';

class ScreenTwo extends StatelessWidget {
  const ScreenTwo({super.key});

  static const Color bgColor = Color(0xFF077C6A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Image.asset(
          "lib/components/welcomePages/images/ob-schedule.jpg",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
