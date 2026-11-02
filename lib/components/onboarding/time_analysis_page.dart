import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class TimeAnalysisPage extends StatelessWidget {
  const TimeAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenTime = OnboardingData.instance.dailyScreenTime;

    int hoursPerDay = 4;
    int fullDaysYear = 91;
    int yearsLifetime = 14;

    if (screenTime == '< 2 hours') {
      hoursPerDay = 2;
      fullDaysYear = 45;
      yearsLifetime = 7;
    } else if (screenTime == '5 - 6 hours') {
      hoursPerDay = 6;
      fullDaysYear = 136;
      yearsLifetime = 21;
    } else if (screenTime == '7+ hours') {
      hoursPerDay = 8;
      fullDaysYear = 182;
      yearsLifetime = 28;
    }

    return Padding(
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
                color: Colors.white.withValues(alpha: 0.85),
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
                const TextSpan(text: "looking at your screen this year."),
              ],
            ),
          ),
          const SizedBox(height: 32),

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
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
