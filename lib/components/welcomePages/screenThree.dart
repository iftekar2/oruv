import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenThree extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const ScreenThree({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  static const Color bgColor = Color(0xFFF1BE41);
  static const Color handleColor = Color(0xFFF1BE41);
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
                    "lib/components/welcomePages/images/ob-focus.jpg",
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
                          "FOCUS ANYWHERE",
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
                          "Create focus modes for work, school or\ncollege and win back hours of attention.",
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

                    // Avatar badge & Focused people metric
                    SizedBox(
                      height: 48,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 68,
                              height: 28,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8C6D73),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBgColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 18,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF077C6A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBgColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 36,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1BE41),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBgColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "12K+",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1A1D),
                                  ),
                                ),
                                Text(
                                  "Focused people",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8A8287),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBgColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          "Get Started",
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
