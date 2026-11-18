import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/services/screen_time_service.dart';

class InsightsHeroHeader extends StatelessWidget {
  final int displayMinutes;
  final bool isWeek;
  final String selectedGranularity;
  final ValueChanged<String> onGranularityChanged;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);

  const InsightsHeroHeader({
    super.key,
    required this.displayMinutes,
    required this.isWeek,
    required this.selectedGranularity,
    required this.onGranularityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWeek ? 'Daily Average' : 'Screen Time',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: _mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppScreenTimeItem.formatMinutes(displayMinutes),
              style: GoogleFonts.lora(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: _primaryText,
                letterSpacing: -1.0,
                height: 1.05,
              ),
            ),
          ],
        ),

        // Granularity Switcher: ( D )  W
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: InsightsGranularityPill(
            selectedGranularity: selectedGranularity,
            onChanged: onGranularityChanged,
          ),
        ),
      ],
    );
  }
}

class InsightsGranularityPill extends StatelessWidget {
  final String selectedGranularity;
  final ValueChanged<String> onChanged;

  const InsightsGranularityPill({
    super.key,
    required this.selectedGranularity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE9E5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['D', 'W'].map((granularity) {
          final isSelected = selectedGranularity == granularity;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(granularity),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 34),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF262326)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                granularity,
                style: GoogleFonts.lora(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
