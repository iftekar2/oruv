import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeCardBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget metricsChild;

  const WelcomeCardBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metricsChild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: const Color(0xFF1E1A1D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Center(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF8A8287),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE5DF)),
          ),
          child: metricsChild,
        ),
      ],
    );
  }
}

class TwoColumnMetrics extends StatelessWidget {
  final String leftVal;
  final String leftLabel;
  final String rightVal;
  final String rightLabel;

  const TwoColumnMetrics({
    super.key,
    required this.leftVal,
    required this.leftLabel,
    required this.rightVal,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                leftVal,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1A1D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                leftLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A8287),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 32,
          width: 1,
          color: const Color(0xFFE5DFD9),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                rightVal,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1A1D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rightLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A8287),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommunityMetric extends StatelessWidget {
  static const Color _cardBgColor = Color(0xFFFDFCF8);

  const CommunityMetric({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          height: 28,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C6D73),
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBgColor, width: 2),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF077C6A),
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBgColor, width: 2),
                  ),
                ),
              ),
              Positioned(
                left: 36,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1BE41),
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBgColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "12K+",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1A1D),
              ),
            ),
            Text(
              "Focused people",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A8287),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
