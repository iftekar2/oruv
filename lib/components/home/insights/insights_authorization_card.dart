import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightsAuthorizationCard extends StatelessWidget {
  final VoidCallback? onConnect;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEFEBE8);
  static const Color _cardBg = Colors.white;
  static const Color _emeraldGreen = Color(0xFF16654E);

  const InsightsAuthorizationCard({
    super.key,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect Screen Time',
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Authorize Screen Time to see accurate per-app breakdown on this device.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _emeraldGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Connect Now',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
