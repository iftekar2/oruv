import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RuleEditorModeSelector extends StatelessWidget {
  final List<String> options;
  final String selectedMode;
  final ValueChanged<String> onModeSelected;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEBE6E1);
  static const Color _accentGreen = Color(0xFF1D6F58);

  const RuleEditorModeSelector({
    super.key,
    required this.options,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENFORCEMENT MODE',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: options.map((mode) {
            final isSelected = selectedMode == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onModeSelected(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _accentGreen : _cardBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: isSelected ? _accentGreen : _mutedText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mode,
                          style: GoogleFonts.lora(
                            fontSize: 13.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
