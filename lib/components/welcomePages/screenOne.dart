import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenOne extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const ScreenOne({super.key, required this.onNext, required this.onSkip});

  static const Color bgColor = Color(0xFF8C6D73);
  static const Color handleColor = Color(0xFF8C6D73);
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
                    "lib/components/welcomePages/images/ob-block.jpg",
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
                          "BLOCK DISTRACTIONS",
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
                          "Lock Instagram, TikTok and any app that\npulls you away \u2014 no willpower needed.",
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

                    // Metrics row
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
                                      "2h+",
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Saved daily",
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
                                      "50+",
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Apps blockable",
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
