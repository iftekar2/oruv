import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/appleSignInButton.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/services/apple_auth_service.dart';

class AppleSignIn extends StatefulWidget {
  const AppleSignIn({super.key});

  @override
  State<AppleSignIn> createState() => _AppleSignInState();
}

class _AppleSignInState extends State<AppleSignIn> {
  bool _isLoading = false;

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final res = await AppleAuthService.signInWithApple(context);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res != null && res.session != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.apple, size: 70, color: Colors.black),
              ),

              const SizedBox(height: 30),
              Text(
                "Sign in with Apple",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "Use your Apple ID to sign in to Oruv securely.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 40),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                )
              else
                AppleSignInButton(
                  onPressed: _handleAppleSignIn,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
