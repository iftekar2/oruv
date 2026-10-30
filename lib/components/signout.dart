import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/welcomePages/welcomePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignOut extends StatefulWidget {
  const SignOut({super.key});

  @override
  State<SignOut> createState() => _SignOutState();
}

class _SignOutState extends State<SignOut> {
  bool _isLoading = false;

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Profile & Settings",
          style: TextStyle(
            color: Colors.black,
            fontFamily: GoogleFonts.sora().fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.black12, width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                email,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.sora().fontFamily,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Logged in",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.logout, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.sora().fontFamily,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
