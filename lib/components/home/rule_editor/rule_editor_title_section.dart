import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RuleEditorTitleSection extends StatelessWidget {
  final TextEditingController controller;
  final List<String> presetNames;
  final ValueChanged<String> onPresetSelected;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEBE6E1);
  static const Color _accentGreen = Color(0xFF1D6F58);

  const RuleEditorTitleSection({
    super.key,
    required this.controller,
    required this.presetNames,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCHEDULE NAME',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.lora(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Work Time, Study Block',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: _accentGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presetNames.map((preset) {
              final isMatch = controller.text == preset;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onPresetSelected(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMatch ? const Color(0xFFE6F5F0) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMatch ? _accentGreen : _cardBorder,
                      ),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isMatch ? _accentGreen : _mutedText,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
