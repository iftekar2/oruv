import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeepWorkAnchorCard extends StatelessWidget {
  final String shieldLabel;
  final String title;
  final String scheduleStart;
  final String scheduleEnd;
  final String remainingCycleText;
  final double progress;
  final String focusedDuration;
  final int pickupsSaved;
  final int focusScore;
  final bool isOnBreak;
  final VoidCallback onTakeMindfulBreak;
  final VoidCallback onAdjust;

  const DeepWorkAnchorCard({
    super.key,
    this.shieldLabel = 'Work Time Shield',
    this.title = 'Deep Work Anchor',
    this.scheduleStart = '9:00 AM',
    this.scheduleEnd = '5:00 PM',
    this.remainingCycleText = '3h 15m remaining in current cycle',
    this.progress = 0.72,
    this.focusedDuration = '1h 45m',
    this.pickupsSaved = 18,
    this.focusScore = 88,
    this.isOnBreak = false,
    required this.onTakeMindfulBreak,
    required this.onAdjust,
  });

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);
  static const Color _darkNavyButton = Color(0xFF131B26);

  @override
  Widget build(BuildContext context) {
    final percentValue = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Title info + Circular Progress Ring
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Work Time Shield row
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: _accentGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shieldLabel,
                          style: GoogleFonts.lora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.lora(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scheduled block: $scheduleStart \u2013 $scheduleEnd',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 72% Progress Ring
              SizedBox(
                width: 62,
                height: 62,
                child: CustomPaint(
                  painter: _AnchorProgressRingPainter(
                    progress: progress,
                    activeColor: _accentGreen,
                    trackColor: const Color(0xFFE8E4DF),
                  ),
                  child: Center(
                    child: Text(
                      '$percentValue%',
                      style: GoogleFonts.lora(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Remaining cycle pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOnBreak
                  ? const Color(0xFFE6F5F0)
                  : const Color(0xFFF3ECEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isOnBreak
                        ? const Color(0xFFF59E0B)
                        : _accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isOnBreak
                        ? 'Mindful break active \u2013 shields paused'
                        : remainingCycleText,
                    style: GoogleFonts.lora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2B2628),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(
            color: Color(0xFFF1EDE9),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 18),

          // 3-Column Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  value: focusedDuration,
                  label: 'Focused',
                  valueColor: _primaryText,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFEEEAE6),
              ),
              Expanded(
                child: _buildMetricColumn(
                  value: '$pickupsSaved',
                  label: 'Pickups Saved',
                  valueColor: _primaryText,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFEEEAE6),
              ),
              Expanded(
                child: _buildMetricColumn(
                  value: '$focusScore',
                  label: 'Focus Score',
                  valueColor: _accentGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Primary Button: Take Mindful Break
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onTakeMindfulBreak,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkNavyButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnBreak
                        ? Icons.play_circle_outline_rounded
                        : Icons.self_improvement_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnBreak ? 'Resume Deep Work' : 'Take Mindful Break',
                    style: GoogleFonts.lora(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Button: Adjust
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onAdjust,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryText,
                side: const BorderSide(
                  color: _cardBorder,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _primaryText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adjust',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: _mutedText,
          ),
        ),
      ],
    );
  }
}

class _AnchorProgressRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _AnchorProgressRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Starts at bottom-left (~7:30 position) and sweeps clockwise, matching design
    const startAngle = math.pi * 0.72;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnchorProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

