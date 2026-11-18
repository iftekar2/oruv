import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightsMetricsCard extends StatelessWidget {
  final String distractedPercentage;
  final String timeSavedDuration;
  final String timeSavedLabel;
  final bool isSavingTime;
  final String rightValue;
  final String rightLabel;
  final Color rightColor;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _emeraldGreen = Color(0xFF16654E);
  static const Color _redBarColor = Color(0xFFE53935);

  const InsightsMetricsCard({
    super.key,
    required this.distractedPercentage,
    required this.timeSavedDuration,
    required this.timeSavedLabel,
    required this.isSavingTime,
    required this.rightValue,
    required this.rightLabel,
    required this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EAE6), width: 1.2),
      ),
      child: Row(
        children: [
          // Column 1: Distracted
          Expanded(
            child: InsightMetricColumn(
              value: distractedPercentage,
              label: 'Distracted',
              valueColor: _primaryText,
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFEFE8E5)),
          // Column 2: TIME SAVED / DAILY GOAL
          Expanded(
            child: InsightMetricColumn(
              value: timeSavedDuration,
              label: timeSavedLabel,
              valueColor: isSavingTime ? _emeraldGreen : _redBarColor,
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFEFE8E5)),
          // Column 3: PICKUPS/HR or LAST WEEK
          Expanded(
            child: InsightMetricColumn(
              value: rightValue,
              label: rightLabel,
              valueColor: rightColor,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightMetricColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  static const Color _mutedText = Color(0xFF6E6A6E);

  const InsightMetricColumn({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.lora(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: valueColor,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: _mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
