import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppScreenTimeItem {
  final String id;
  final String name;
  final int durationMinutes;
  final Color barColor;
  final Widget? icon;

  const AppScreenTimeItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.barColor,
    this.icon,
  });

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }
}

class DailyScreenTimeCard extends StatelessWidget {
  final int? totalMinutes;
  final List<AppScreenTimeItem>? apps;
  final VoidCallback? onTapHeader;

  const DailyScreenTimeCard({
    super.key,
    this.totalMinutes,
    this.apps,
    this.onTapHeader,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);
  static const Color _coralPink = Color(0xFFF26879);
  static const Color _emeraldGreen = Color(0xFF1D6F58);
  static const Color _trackColor = Color(0xFFF3ECEB);

  List<AppScreenTimeItem> get _effectiveApps {
    if (apps != null && apps!.isNotEmpty) return apps!;
    return [
      AppScreenTimeItem(
        id: 'instagram',
        name: 'Instagram',
        durationMinutes: 88, // 1h 28m
        barColor: _coralPink,
        icon: _buildInstagramIcon(),
      ),
      AppScreenTimeItem(
        id: 'tiktok',
        name: 'TikTok',
        durationMinutes: 87, // 1h 27m
        barColor: _coralPink,
        icon: _buildTikTokIcon(),
      ),
      AppScreenTimeItem(
        id: 'oruv',
        name: 'Oruv',
        durationMinutes: 65, // 1h 5m
        barColor: _emeraldGreen,
        icon: _buildOruvIcon(),
      ),
      AppScreenTimeItem(
        id: 'youtube',
        name: 'YouTube',
        durationMinutes: 52, // 52m
        barColor: _coralPink,
        icon: _buildYouTubeIcon(),
      ),
      AppScreenTimeItem(
        id: 'edits',
        name: 'Edits',
        durationMinutes: 14, // 14m
        barColor: const Color(0xFF3BBA9C),
        icon: _buildEditsIcon(),
      ),
    ];
  }

  int get _effectiveTotalMinutes {
    if (totalMinutes != null && totalMinutes! > 0) return totalMinutes!;
    return 395; // 6h 35m matching screenshot
  }

  String get _formattedTotalDuration {
    final total = _effectiveTotalMinutes;
    final h = total ~/ 60;
    final m = total % 60;
    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appItems = _effectiveApps;
    final maxAppMinutes = appItems.isEmpty
        ? 1
        : appItems
            .map((e) => e.durationMinutes)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Screen Time >"
          GestureDetector(
            onTap: onTapHeader,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Screen Time',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _mutedText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _mutedText,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Total duration headline: "6h 35m"
          Text(
            _formattedTotalDuration,
            style: GoogleFonts.lora(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: _primaryText,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 3),

          // Subtitle: "Today"
          Text(
            'Today',
            style: GoogleFonts.inter(
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
          const SizedBox(height: 14),

          // List of apps with icons, names, horizontal bars, and times
          Column(
            children: appItems.map((item) {
              final ratio = (item.durationMinutes / maxAppMinutes).clamp(0.08, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    // App Icon
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: item.icon ?? _buildDefaultIcon(item.name),
                    ),
                    const SizedBox(width: 12),

                    // App Name + Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.lora(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                              Text(
                                item.formattedDuration,
                                style: GoogleFonts.lora(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: item.barColor == _emeraldGreen
                                      ? _emeraldGreen
                                      : _primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          // Horizontal Bar matching screenshot layout
                          Container(
                            height: 4.5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _trackColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: ratio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: item.barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- App Icons Styling ---

  static Widget _buildInstagramIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: const RadialGradient(
          center: Alignment(-0.8, 0.9),
          radius: 1.2,
          colors: [
            Color(0xFFFFDC80),
            Color(0xFFFD1D1D),
            Color(0xFFC13584),
            Color(0xFF833AB4),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.5),
          border: Border.all(color: Colors.white, width: 1.8),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6.5,
          height: 6.5,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 1.8),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTikTokIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F10),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  static Widget _buildOruvIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFECE8E4), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        'lib/components/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget _buildYouTubeIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  static Widget _buildEditsIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2A38), Color(0xFF17161F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF3E3B4D), width: 1),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Color(0xFF3BBA9C),
        size: 18,
      ),
    );
  }

  static Widget _buildDefaultIcon(String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE7),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _primaryText,
        ),
      ),
    );
  }
}

