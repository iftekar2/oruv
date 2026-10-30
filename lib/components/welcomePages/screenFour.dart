import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/appleSignInButton.dart';
import 'package:oruv/components/auth/components/appleSignUpButton.dart';
import 'package:oruv/components/auth/components/emailSignInButton.dart';
import 'package:oruv/components/auth/components/emailSignUpButton.dart';
import 'package:oruv/components/auth/components/googleSignInButton.dart';
import 'package:oruv/components/auth/components/googleSignUpButton.dart';
import 'package:oruv/components/auth/emailSignIn.dart';
import 'package:oruv/components/auth/emailSignUp.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/services/google_auth_service.dart';

class ScreenFour extends StatefulWidget {
  const ScreenFour({super.key});

  @override
  State<ScreenFour> createState() => _ScreenFourState();
}

class _ScreenFourState extends State<ScreenFour> {
  bool _isSignUpMode = false;
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final res = await GoogleAuthService.signInWithGoogle(context);

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
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
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "lib/components/images/welcome-image.jpg",
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Welcome",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.sora().fontFamily,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Let your journey start from here",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.sora().fontFamily,
                  ),
                ),

                const SizedBox(height: 28),

                // Toggle between Sign In and Sign Up
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSignUpMode = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isSignUpMode
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: !_isSignUpMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: !_isSignUpMode
                                    ? const Color(0xff4063e4)
                                    : Colors.grey.shade600,
                                fontFamily: GoogleFonts.sora().fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSignUpMode = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isSignUpMode
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: _isSignUpMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _isSignUpMode
                                    ? const Color(0xff4063e4)
                                    : Colors.grey.shade600,
                                fontFamily: GoogleFonts.sora().fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign In / Sign Up buttons
                if (!_isSignUpMode) ...[
                  GoogleSignInButton(
                    onPressed: _isGoogleLoading ? null : _handleGoogleAuth,
                  ),

                  const SizedBox(height: 14),

                  AppleSignInButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  EmailSignInButton(
                    text: "Sign in with Email",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailSignIn(),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  GoogleSignUpButton(
                    onPressed: _isGoogleLoading ? null : _handleGoogleAuth,
                  ),

                  const SizedBox(height: 14),

                  AppleSignUpButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  EmailSignUpButton(
                    text: "Sign up with Email",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailSignUp(),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Switcher helper
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      !_isSignUpMode
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontFamily: GoogleFonts.sora().fontFamily,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                        });
                      },
                      child: Text(
                        !_isSignUpMode ? "Sign Up" : "Sign In",
                        style: TextStyle(
                          color: const Color(0xff4063e4),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: GoogleFonts.sora().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
