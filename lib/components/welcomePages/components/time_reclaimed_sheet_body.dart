import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class TimeReclaimedSheetBody extends StatelessWidget {
  const TimeReclaimedSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final screenTime = OnboardingData.instance.dailyScreenTime;
    String reclaimedDaily = "2h 30m";
    int daysGivenBack = 38;

    if (screenTime == '< 2 hours') {
      reclaimedDaily = "1h 15m";
      daysGivenBack = 19;
    } else if (screenTime == '5 - 6 hours') {
      reclaimedDaily = "3h 45m";
      daysGivenBack = 57;
    } else if (screenTime == '7+ hours') {
      reclaimedDaily = "5h 00m";
      daysGivenBack = 76;
    }

    return Column(
      key: const ValueKey('time_reclaimed_sheet'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Divider(color: Color(0xFFEBE5DF), thickness: 0.8),
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
        const SizedBox(height: 4),
      ],
    );
  }
}
