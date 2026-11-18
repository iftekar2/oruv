import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RuleEditorTimePicker extends StatelessWidget {
  final String startTime;
  final String endTime;
  final void Function({required bool isStart}) onPickTime;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEBE6E1);
  static const Color _accentGreen = Color(0xFF1D6F58);

  const RuleEditorTimePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIME BLOCK',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onPickTime(isStart: true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STARTS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _mutedText,
                            ),
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: _accentGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        startTime,
                        style: GoogleFonts.lora(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => onPickTime(isStart: false),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UNLOCKS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _mutedText,
                            ),
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: _accentGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        endTime,
                        style: GoogleFonts.lora(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
