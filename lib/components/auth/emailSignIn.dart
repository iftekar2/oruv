import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/appleSignInButton.dart';
import 'package:oruv/components/auth/components/authButton.dart';
import 'package:oruv/components/auth/components/authTextField.dart';
import 'package:oruv/components/auth/components/googleSignInButton.dart';
import 'package:oruv/components/auth/emailSignUp.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailSignIn extends StatefulWidget {
  const EmailSignIn({super.key});

  @override
  State<EmailSignIn> createState() => _EmailSignInState();
}

class _EmailSignInState extends State<EmailSignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: $e"),
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
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign in to your Oruv account to keep distractions away.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 32),

              AuthTextField(
                label: "Email Address",
                hintText: "Enter your email",
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              AuthTextField(
                label: "Password",
                hintText: "Enter your password",
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: const Color(0xff4063e4),
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.sora().fontFamily,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AuthButton(
                text: "Sign In",
                isLoading: _isLoading,
                onPressed: _signIn,
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      "or continue with",
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

              GoogleSignInButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 14),

              AppleSignInButton(
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
                    "Don't have an account? ",
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
                          builder: (context) => const EmailSignUp(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign Up",
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
