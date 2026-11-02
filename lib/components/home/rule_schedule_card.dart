import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';

class RuleScheduleCard extends StatelessWidget {
  final ScheduleRuleModel rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final double? width;

  const RuleScheduleCard({
    super.key,
    required this.rule,
    required this.onToggle,
    this.onTap,
    this.width,
  });

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 242,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Active Badge + Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: rule.isActive
                        ? const Color(0xFFBCEFD6)
                        : const Color(0xFFEEECE9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: rule.isActive
                              ? const Color(0xFF0E6346)
                              : const Color(0xFF8A8488),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        rule.isActive ? 'Active' : 'Paused',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: rule.isActive
                              ? const Color(0xFF0E6346)
                              : const Color(0xFF6E6A6E),
                        ),
                      ),
                    ],
                  ),
                ),

                // Clean iOS-style pill toggle matching the design
                GestureDetector(
                  onTap: () => onToggle(!rule.isActive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 46,
                    height: 26,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: rule.isActive
                          ? _accentGreen
                          : const Color(0xFFDAD6D1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: rule.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Time range with clock icon
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: _primaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.timeRange,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Rule Title
            Text(
              rule.title,
              style: GoogleFonts.lora(
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),

            const SizedBox(height: 4),

            // Enforcement Mode Subtitle
            Text(
              rule.enforcementMode,
              style: GoogleFonts.lora(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: _mutedText,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(
              color: Color(0xFFF2EEEA),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 12),

            // Bottom Row: Overlapping App Badges + Blocked Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverlappingBadges(rule.badges),
                Text(
                  '${rule.blockedCount} Blocked',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlappingBadges(List<AppBadgeInfo> badges) {
    if (badges.isEmpty) return const SizedBox.shrink();

    const double circleSize = 25;
    const double overlapOffset = 17;
    final totalWidth =
        circleSize + (badges.length - 1) * overlapOffset + 4;

    return SizedBox(
      width: totalWidth,
      height: circleSize,
      child: Stack(
        children: List.generate(badges.length, (index) {
          final badge = badges[index];
          final isExtraCounter = badge.label.startsWith('+');
          return Positioned(
            left: index * overlapOffset,
            child: Container(
              width: isExtraCounter ? 27 : circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: badge.backgroundColor,
                borderRadius: BorderRadius.circular(circleSize / 2),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge.label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: badge.textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

