import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class TimeAnalysisPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const TimeAnalysisPage({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenTime = OnboardingData.instance.dailyScreenTime;

    // Projections derived from selected screen time
    int hoursPerDay = 4;
    int fullDaysYear = 91;
    int yearsLifetime = 14;
    String reclaimedDaily = "2h 30m";
    int daysGivenBack = 38;

    if (screenTime == '< 2 hours') {
      hoursPerDay = 2;
      fullDaysYear = 45;
      yearsLifetime = 7;
      reclaimedDaily = "1h 15m";
      daysGivenBack = 19;
    } else if (screenTime == '5 - 6 hours') {
      hoursPerDay = 6;
      fullDaysYear = 136;
      yearsLifetime = 21;
      reclaimedDaily = "3h 45m";
      daysGivenBack = 57;
    } else if (screenTime == '7+ hours') {
      hoursPerDay = 8;
      fullDaysYear = 182;
      yearsLifetime = 28;
      reclaimedDaily = "5h 00m";
      daysGivenBack = 76;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: onBack,
                      color: Colors.white,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    "Step 3 of 5",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Top Hero Black Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // At X hours a day...
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        children: [
                          const TextSpan(text: "At "),
                          TextSpan(
                            text: "$hoursPerDay hours a day",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const TextSpan(text: ", you will spend "),
                          TextSpan(
                            text: "$fullDaysYear full days\n",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const TextSpan(
                            text: "looking at your screen this year.",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 14 Years
                    Text(
                      "$yearsLifetime Years",
                      style: GoogleFonts.outfit(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      "of your conscious life lost to unintentional\nscreen drift.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.45,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom White Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF8),
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
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0DCD6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "TIME RECLAIMED",
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: const Color(0xFF1E1A1D),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Honest projections when friction is placed between\nimpulse and action.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.4,
                        color: const Color(0xFF8A8287),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEBE5DF)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      reclaimedDaily,
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Reclaimed daily",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF8A8287),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: const Color(0xFFE5DFD9),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "$daysGivenBack Days",
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Given back / yr",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF8A8287),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                            color: Color(0xFFEBE5DF),
                            thickness: 0.8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "94%",
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF077C6A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Report less fog",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A8287),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Primary Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1A1D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          "I Want My Time Back",
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dots progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDED7CE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 20,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF281F24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDED7CE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDED7CE),
                            shape: BoxShape.circle,
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
