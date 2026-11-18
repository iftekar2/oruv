import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class AppShieldStatusRow extends StatelessWidget {
  const AppShieldStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (!OnboardingData.instance.screenTimeAuthorized) {
      return const SizedBox.shrink(key: ValueKey('app_shield_perm'));
    }

    final appCount = OnboardingData.instance.totalSelectedAppsCount;

    return Padding(
      key: const ValueKey('app_shield_status'),
      padding: const EdgeInsets.only(top: 14.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: appCount > 0
                  ? const Color(0xFF077C6A)
                  : const Color(0xFFB5AFB3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$appCount ${appCount == 1 ? 'App' : 'Apps'} Selected",
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1A1D),
            ),
          ),
          if (appCount > 0) ...[
            const Spacer(),
            Text(
              "~3.5h saved daily",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A8287),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
