import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const UserProfilePage({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: OnboardingData.instance.fullName,
    );
    _ageController = TextEditingController(
      text: OnboardingData.instance.age != null
          ? OnboardingData.instance.age.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      OnboardingData.instance.fullName = _nameController.text.trim();
      OnboardingData.instance.age = int.tryParse(_ageController.text.trim());
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: widget.onBack,
                      color: const Color(0xFF1E1A1D),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    "Step 1 of 5",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8A8287),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      Text(
                        "Let's get to\nknow you.",
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          color: const Color(0xFF1E1A1D),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "We personalize your daily focus containers based on your stage in life.",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.45,
                          color: const Color(0xFF6E686D),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Full Name Field
                      Text(
                        "FULL NAME",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: const Color(0xFF1E1A1D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1A1D),
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your full name",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFFB5AFB3),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F8F6),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF6E686D),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFFEBE5DF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFFEBE5DF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF077C6A),
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Age Field
                      Text(
                        "YOUR AGE",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: const Color(0xFF1E1A1D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1A1D),
                        ),
                        decoration: InputDecoration(
                          hintText: "e.g. 24",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFFB5AFB3),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F8F6),
                          prefixIcon: const Icon(
                            Icons.cake_outlined,
                            color: Color(0xFF6E686D),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFFEBE5DF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFFEBE5DF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF077C6A),
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your age";
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 10 || parsed > 120) {
                            return "Please enter a valid age";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Continue Sheet
            Container(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DCD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF281F24),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

