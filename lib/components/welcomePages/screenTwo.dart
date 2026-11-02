import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenTwo extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const ScreenTwo({super.key, required this.onNext, required this.onSkip});

  static const Color bgColor = Color(0xFF077C6A);
  static const Color handleColor = Color(0xFF077C6A);
  static const Color cardBgColor = Color(0xFFFDFCF8);
  static const Color buttonBgColor = Color(0xFF281F24);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Illustration area
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    "lib/components/welcomePages/images/ob-schedule.jpg",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Bottom White Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pull / accent bar
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    SizedBox(
                      height: 38,
                      child: Center(
                        child: Text(
                          "SET YOUR SCHEDULE",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: const Color(0xFF1E1A1D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle / Description
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          "Block social media at 10 PM and get it back\nat 8 AM. It runs on its own, every day.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8A8287),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Schedule Times row
                    SizedBox(
                      height: 48,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "10 PM",
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Apps lock",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8A8287),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 38,
                                width: 1,
                                color: const Color(0xFFE5DFD9),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "8 AM",
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Apps unlock",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8A8287),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBgColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          "Next",
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Indicators & Skip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDED7CE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 22,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF281F24),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDED7CE),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onSkip,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A8287),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
