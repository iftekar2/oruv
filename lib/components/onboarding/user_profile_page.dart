import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const UserProfilePage({super.key, this.onSubmitted});

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
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

  bool validateAndSave() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      OnboardingData.instance.fullName = _nameController.text.trim();
      OnboardingData.instance.age = int.tryParse(_ageController.text.trim());
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                "Let's get to\nknow you.",
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  color: const Color(0xFF1E1A1D),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We personalize your daily focus containers based on your stage in life.",
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.45,
                  color: const Color(0xFF6E686D),
                ),
              ),
              const SizedBox(height: 28),

              // Editorial Card Container for inputs
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFECE7E2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name Field
                    Text(
                      "FULL NAME",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFF8A8287),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      keyboardAppearance: Brightness.light,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onChanged: (val) {
                        OnboardingData.instance.fullName = val.trim();
                      },
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
                        fillColor: const Color(0xFFFBF9F7),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF6E686D),
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFECE7E2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFECE7E2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF077C6A),
                            width: 1.8,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your full name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    // Age Field
                    Text(
                      "YOUR AGE",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFF8A8287),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ageController,
                      keyboardAppearance: Brightness.light,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onChanged: (val) {
                        OnboardingData.instance.age = int.tryParse(val.trim());
                      },
                      onFieldSubmitted: (_) {
                        if (validateAndSave()) {
                          widget.onSubmitted?.call();
                        }
                      },
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
                        fillColor: const Color(0xFFFBF9F7),
                        prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: Color(0xFF6E686D),
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFECE7E2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFECE7E2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
