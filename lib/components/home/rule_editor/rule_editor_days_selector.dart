import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RuleEditorDaysSelector extends StatelessWidget {
  final List<String> dayKeys;
  final List<String> dayLabels;
  final Set<String> activeDays;
  final ValueChanged<String> onDayToggled;

  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEBE6E1);

  const RuleEditorDaysSelector({
    super.key,
    required this.dayKeys,
    required this.dayLabels,
    required this.activeDays,
    required this.onDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE DAYS',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dayKeys.length, (idx) {
            final key = dayKeys[idx];
            final label = dayLabels[idx];
            final isSelected = activeDays.contains(key);
            return GestureDetector(
              onTap: () => onDayToggled(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF131B26)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF131B26)
                        : _cardBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _mutedText,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
