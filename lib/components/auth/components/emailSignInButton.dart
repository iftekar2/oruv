import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const EmailSignInButton({
    super.key,
    this.onPressed,
    this.text = "Sign in with Email",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4063e4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: GoogleFonts.sora().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
