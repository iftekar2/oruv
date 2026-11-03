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
    final badges = rule.badges;
    final isRunningNow = rule.isCurrentlyRunning;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Running Status Pill (left) + User Enable Toggle (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Only show green "Active" pill if this rule is currently running right now
                if (isRunningNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCEFD6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E6346),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0E6346),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEECE9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8A8488),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rule.isActive ? 'Scheduled' : 'Off',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6E6A6E),
                          ),
                        ),
                      ],
                    ),
                  ),

                // User toggle switch: stays green whenever rule.isActive is true
                GestureDetector(
                  onTap: () => onToggle(!rule.isActive),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 23,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: rule.isActive
                          ? _accentGreen
                          : const Color(0xFFDAD6D1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: rule.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 19,
                        height: 19,
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

            const SizedBox(height: 12),

            // Time range with clock icon
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13.5,
                  color: _primaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    rule.timeRange,
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // Rule Title
            Text(
              rule.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),

            const SizedBox(height: 3),

            // Enforcement Mode Subtitle
            Text(
              rule.enforcementMode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: _mutedText,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(
              color: Color(0xFFF2EEEA),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 10),

            // Bottom Row: Overlapping App Badges + Blocked Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverlappingBadges(badges),
                Flexible(
                  child: Text(
                    '${rule.blockedCount} Blocked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _mutedText,
                    ),
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
    if (badges.isEmpty) {
      return Text(
        'No apps',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: _mutedText,
        ),
      );
    }

    const double circleSize = 22;
    const double overlapOffset = 14.5;
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
              width: isExtraCounter ? 24 : circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: badge.backgroundColor,
                borderRadius: BorderRadius.circular(circleSize / 2),
                border: Border.all(
                  color: Colors.white,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge.label,
                style: GoogleFonts.inter(
                  fontSize: 8.2,
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

class AddScheduleGridCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddScheduleGridCard({
    super.key,
    required this.onTap,
  });

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2DDD7),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F5F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 24,
                color: _accentGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'New Schedule',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add block time & apps',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 11,
                color: _mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
