import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/appleSignUpButton.dart';
import 'package:oruv/components/auth/components/authButton.dart';
import 'package:oruv/components/auth/components/authTextField.dart';
import 'package:oruv/components/auth/components/googleSignUpButton.dart';
import 'package:oruv/components/auth/emailSignIn.dart';
import 'package:oruv/components/homeScreen.dart';

class EmailSignUp extends StatefulWidget {
  const EmailSignUp({super.key});

  @override
  State<EmailSignUp> createState() => _EmailSignUpState();
}

class _EmailSignUpState extends State<EmailSignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign up to start blocking distractions and reclaim your time.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 28),

              AuthTextField(
                label: "Full Name",
                hintText: "Enter your full name",
                controller: _nameController,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 18),

              AuthTextField(
                label: "Email Address",
                hintText: "Enter your email",
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              AuthTextField(
                label: "Password",
                hintText: "Create a password",
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 18),

              AuthTextField(
                label: "Confirm Password",
                hintText: "Confirm your password",
                controller: _confirmPasswordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 24),

              AuthButton(
                text: "Sign Up",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      "or sign up with",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontFamily: GoogleFonts.sora().fontFamily,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 24),

              GoogleSignUpButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              AppleSignUpButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: GoogleFonts.sora().fontFamily,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailSignIn(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: const Color(0xff4063e4),
                        fontWeight: FontWeight.bold,
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
    );
  }
}
