import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/services/screen_time_service.dart';

class InsightsSectionHeader extends StatelessWidget {
  final String title;
  final String durationText;

  static const Color _primaryText = Color(0xFF1B1B1D);

  const InsightsSectionHeader({
    super.key,
    required this.title,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _primaryText,
          ),
        ),
        Text(
          durationText,
          style: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
      ],
    );
  }
}

class InsightsAppCard extends StatelessWidget {
  final List<AppScreenTimeItem> apps;
  final int maxAppMinutes;
  final Color defaultBarColor;
  final String emptyMessage;
  final bool isOtherSection;

  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _emeraldGreen = Color(0xFF16654E);
  static const Color _mintBarColor = Color(0xFF74C69D);
  static const Color _greyBarColor = Color(0xFF7E7777);
  static const Color _dividerColor = Color(0xFFF4EFEA);

  const InsightsAppCard({
    super.key,
    required this.apps,
    required this.maxAppMinutes,
    required this.defaultBarColor,
    required this.emptyMessage,
    this.isOtherSection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: apps.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyMessage,
                style: GoogleFonts.lora(fontSize: 13, color: _mutedText),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: _dividerColor, height: 22, thickness: 1),
              itemBuilder: (context, index) {
                final item = apps[index];
                final ratio = (item.durationMinutes / maxAppMinutes).clamp(
                  0.06,
                  1.0,
                );

                final isOruv = item.name.toLowerCase().contains('oruv');
                final isBrowser =
                    item.name.toLowerCase().contains('safari') ||
                    item.name.toLowerCase().contains('chrome');

                Color barColor = defaultBarColor;
                if (isOtherSection) {
                  if (isOruv) {
                    barColor = _emeraldGreen;
                  } else if (isBrowser) {
                    barColor = _mintBarColor;
                  } else {
                    barColor = _greyBarColor;
                  }
                }

                return InsightsAppItem(
                  icon: buildAppIcon(item),
                  title: item.name,
                  subtitle: isOruv ? 'Deep Work' : null,
                  durationText: item.formattedDuration,
                  progressRatio: ratio,
                  barColor: barColor,
                );
              },
            ),
    );
  }

  static Widget buildAppIcon(AppScreenTimeItem item) {
    if (item.iconBytes != null && item.iconBytes!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFECE8E4), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.memory(
            item.iconBytes!,
            fit: BoxFit.cover,
            cacheWidth: 114,
            cacheHeight: 114,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => buildMonogramIcon(item.name),
          ),
        ),
      );
    }
    return buildMonogramIcon(item.name);
  }

  static Widget buildMonogramIcon(String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE7),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B1B1D),
        ),
      ),
    );
  }
}

class InsightsAppItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final String durationText;
  final double progressRatio;
  final Color barColor;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _emeraldGreen = Color(0xFF16654E);
  static const Color _trackColor = Color(0xFFF3EBE9);

  const InsightsAppItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.durationText,
    required this.progressRatio,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 38, height: 38, child: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _emeraldGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              durationText,
              style: GoogleFonts.lora(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 7,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _trackColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressRatio,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
