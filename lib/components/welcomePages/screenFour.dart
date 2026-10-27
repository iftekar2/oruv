import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenFour extends StatefulWidget {
  const ScreenFour({super.key});

  @override
  State<ScreenFour> createState() => _ScreenFourState();
}

class _ScreenFourState extends State<ScreenFour> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(backgroundColor: Colors.white),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("lib/components/images/welcome-image.jpg"),

            Text(
              "Welcome",
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.w500),
            ),

            Text(
              "Let your journey start from here",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
                fontFamily: GoogleFonts.sora().fontFamily,
              ),
            ),

            TextButton(
              onPressed: () {},
              child: Text("Email"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
