import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/auth/components/authButton.dart';
import 'package:oruv/components/auth/components/authTextField.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthRedirectService.markPendingFlow(
        AuthRedirectFlow.resetPassword,
      );
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: AuthRedirectService.resetPasswordRedirectUrl,
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent! Please check your inbox."),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      await AuthRedirectService.clearPendingFlow(
        AuthRedirectFlow.resetPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      await AuthRedirectService.clearPendingFlow(
        AuthRedirectFlow.resetPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred. Please try again."),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailSent
                    ? "We've sent password reset instructions to ${_emailController.text.trim()}."
                    : "Enter your email address and we'll send you a link to reset your password.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),
              const SizedBox(height: 32),
              if (!_emailSent) ...[
                AuthTextField(
                  label: "Email Address",
                  hintText: "Enter your email",
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                AuthButton(
                  text: "Send Reset Link",
                  isLoading: _isLoading,
                  onPressed: _sendPasswordResetEmail,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff4063e4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 48,
                        color: Color(0xff4063e4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Check your inbox",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: GoogleFonts.sora().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Click the link inside the email to set a new password. If you don't see it, check your spam folder.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontFamily: GoogleFonts.sora().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AuthButton(
                  text: "Resend Email",
                  isLoading: _isLoading,
                  onPressed: _sendPasswordResetEmail,
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Back to Sign In",
                      style: TextStyle(
                        color: const Color(0xff4063e4),
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.sora().fontFamily,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

