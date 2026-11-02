import 'package:flutter/material.dart';

class ScreenOne extends StatelessWidget {
  const ScreenOne({super.key});

  static const Color bgColor = Color(0xFF8C6D73);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Image.asset(
          "lib/components/welcomePages/images/ob-block.jpg",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
