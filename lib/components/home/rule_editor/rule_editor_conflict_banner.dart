import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';

class RuleEditorConflictBanner extends StatelessWidget {
  final ScheduleRuleModel conflict;

  const RuleEditorConflictBanner({
    super.key,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE89A58).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Color(0xFFC06A28),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Conflict',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A4612),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This time overlaps with "${conflict.title}" (${conflict.timeRange}). Please pick another time or adjust active days.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A4612).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
