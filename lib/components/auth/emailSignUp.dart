import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/appleSignUpButton.dart';
import 'package:oruv/components/auth/components/authButton.dart';
import 'package:oruv/components/auth/components/authTextField.dart';
import 'package:oruv/components/auth/components/googleSignUpButton.dart';
import 'package:oruv/components/auth/emailSignIn.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters long"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (!mounted) return;

      if (response.session != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sign up successful! Please check your email for confirmation.",
            ),
            backgroundColor: Color(0xff4063e4),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmailSignIn()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occured. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(backgroundColor: Colors.white),

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
                isLoading: _isLoading,
                onPressed: _signUp,
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 14),
              AppleSignUpButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
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
