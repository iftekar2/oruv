import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/services/screen_time_service.dart';

class InsightsPage extends StatefulWidget {
  final DailyScreenTimeSnapshot? screenTimeSnapshot;
  final VoidCallback? onConnectScreenTime;

  const InsightsPage({
    super.key,
    this.screenTimeSnapshot,
    this.onConnectScreenTime,
  });

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String _selectedGranularity = 'D'; // 'D', 'W', 'M'

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEFEBE8);
  static const Color _cardBg = Colors.white;
  static const Color _emeraldGreen = Color(0xFF16654E);
  static const Color _redBarColor = Color(0xFFE53935);
  static const Color _mintBarColor = Color(0xFF74C69D);
  static const Color _greyBarColor = Color(0xFF7E7777);
  static const Color _trackColor = Color(0xFFF3EBE9);
  static const Color _dividerColor = Color(0xFFF4EFEA);

  List<AppScreenTimeItem> _getDistractingApps(List<AppScreenTimeItem> allApps) {
    return allApps.where((a) => a.isDistracting).toList();
  }

  List<AppScreenTimeItem> _getOtherApps(List<AppScreenTimeItem> allApps) {
    return allApps.where((a) => !a.isDistracting).toList();
  }

  /// Exact sample apps from the design screenshot when no usage is cached yet
  List<AppScreenTimeItem> _buildSampleApps() {
    return const [
      AppScreenTimeItem(
        id: 'sample_tiktok',
        name: 'TikTok',
        durationMinutes: 80, // 1h 20m
        barColor: _redBarColor,
        isDistracting: true,
      ),
      AppScreenTimeItem(
        id: 'sample_instagram',
        name: 'Instagram',
        durationMinutes: 79, // 1h 19m
        barColor: _redBarColor,
        isDistracting: true,
      ),
      AppScreenTimeItem(
        id: 'sample_oruv',
        name: 'Oruv',
        durationMinutes: 61, // 1h 1m
        barColor: _emeraldGreen,
        isDistracting: false,
      ),
      AppScreenTimeItem(
        id: 'sample_safari',
        name: 'Safari',
        durationMinutes: 49,
        barColor: _mintBarColor,
        isDistracting: false,
      ),
      AppScreenTimeItem(
        id: 'sample_snkrs',
        name: 'Nike SNKRS: Sneakers & Apparel',
        durationMinutes: 9,
        barColor: _greyBarColor,
        isDistracting: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rawApps = widget.screenTimeSnapshot?.apps ?? [];
    final effectiveApps = rawApps.isNotEmpty ? rawApps : _buildSampleApps();

    final distractingApps = _getDistractingApps(effectiveApps);
    final otherApps = _getOtherApps(effectiveApps);

    final distractingMins = distractingApps.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    final otherMins = otherApps.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    final totalMins =
        (widget.screenTimeSnapshot?.totalMinutes != null &&
            widget.screenTimeSnapshot!.totalMinutes! > 0)
        ? widget.screenTimeSnapshot!.totalMinutes!
        : (distractingMins + otherMins);

    final pctDistracted = totalMins > 0
        ? ((distractingMins / totalMins) * 100).round().clamp(0, 100)
        : 0;

    final maxAppMins = effectiveApps.isEmpty
        ? 1
        : effectiveApps
              .map((e) => e.durationMinutes)
              .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. TOP HERO: Screen Time + Granularity Switcher ────────
          _buildHeroHeader(totalMins),

          const SizedBox(height: 22),

          // ─── 2. 3-COLUMN METRICS SUMMARY CARD ────────────────────────
          _buildMetricsSummaryCard(
            distractedPercentage: '$pctDistracted%',
            timeSavedDuration: '1h 52m',
            pickupsPerHour: '4',
          ),

          const SizedBox(height: 26),

          // ─── 3. DISTRACTING APPS SECTION ─────────────────────────────
          _buildSectionHeader(
            title: 'Distracting Apps',
            durationText: AppScreenTimeItem.formatMinutes(distractingMins),
          ),
          const SizedBox(height: 10),
          _buildAppCard(
            apps: distractingApps,
            maxAppMinutes: maxAppMins,
            defaultBarColor: _redBarColor,
            emptyMessage: 'No distracting app activity recorded today.',
          ),

          const SizedBox(height: 30),

          // ─── 4. OTHER APPS SECTION ───────────────────────────────────
          _buildSectionHeader(
            title: 'Other Apps',
            durationText: AppScreenTimeItem.formatMinutes(otherMins),
          ),
          const SizedBox(height: 10),
          _buildAppCard(
            apps: otherApps,
            maxAppMinutes: maxAppMins,
            defaultBarColor: _emeraldGreen,
            emptyMessage: 'No other app activity recorded today.',
            isOtherSection: true,
          ),

          if (widget.screenTimeSnapshot?.isAuthorized != true) ...[
            const SizedBox(height: 22),
            _buildAuthorizationPrompt(),
          ],
        ],
      ),
    );
  }

  // ─── HERO HEADER ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader(int totalMinutes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screen Time',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: _mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppScreenTimeItem.formatMinutes(totalMinutes),
              style: GoogleFonts.lora(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: _primaryText,
                letterSpacing: -1.0,
                height: 1.05,
              ),
            ),
          ],
        ),

        // Granularity Switcher: ( D )  W   M
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _buildGranularityPill(),
        ),
      ],
    );
  }

  Widget _buildGranularityPill() {
    return Container(
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE9E5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['D', 'W', 'M'].map((granularity) {
          final isSelected = _selectedGranularity == granularity;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selectedGranularity = granularity);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 34),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF262326)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                granularity,
                style: GoogleFonts.lora(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 3-COLUMN METRICS SUMMARY CARD ───────────────────────────────────────

  Widget _buildMetricsSummaryCard({
    required String distractedPercentage,
    required String timeSavedDuration,
    required String pickupsPerHour,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EAE6), width: 1.2),
      ),
      child: Row(
        children: [
          // Column 1: % DISTRACTED
          Expanded(
            child: _buildMetricColumn(
              value: distractedPercentage,
              label: 'Distracted',
              valueColor: _primaryText,
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFEFE8E5)),
          // Column 2: TIME SAVED
          Expanded(
            child: _buildMetricColumn(
              value: timeSavedDuration,
              label: 'Time Saved',
              valueColor: _emeraldGreen,
            ),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFEFE8E5)),
          // Column 3: PICKUPS/HR
          Expanded(
            child: _buildMetricColumn(
              value: pickupsPerHour,
              label: 'Pickups/HR',
              valueColor: _primaryText,
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
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
      ],
    );
  }

  // ─── SECTION HEADER ──────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required String durationText,
  }) {
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

  // ─── SECTION CARD ────────────────────────────────────────────────────────

  Widget _buildAppCard({
    required List<AppScreenTimeItem> apps,
    required int maxAppMinutes,
    required Color defaultBarColor,
    required String emptyMessage,
    bool isOtherSection = false,
  }) {
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
                final isSafari = item.name.toLowerCase().contains('safari');

                // Bar color logic to match screenshot
                Color barColor = defaultBarColor;
                if (isOtherSection) {
                  if (isOruv) {
                    barColor = _emeraldGreen;
                  } else if (isSafari) {
                    barColor = _mintBarColor;
                  } else {
                    barColor = _greyBarColor;
                  }
                }

                return _buildAppItem(
                  icon: _buildAppIcon(item),
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

  Widget _buildAppItem({
    required Widget icon,
    required String title,
    String? subtitle,
    required String durationText,
    required double progressRatio,
    required Color barColor,
  }) {
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
                      subtitle,
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
        // Wide horizontal progress bar running across the full width
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

  // ─── APP ICONS ───────────────────────────────────────────────────────────

  Widget _buildAppIcon(AppScreenTimeItem item) {
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
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _buildBrandOrMonogramIcon(item.name),
          ),
        ),
      );
    }
    return _buildBrandOrMonogramIcon(item.name);
  }

  Widget _buildBrandOrMonogramIcon(String name) {
    final lower = name.toLowerCase();

    // 1. TikTok: Black rounded box with "Tk"
    if (lower.contains('tiktok')) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          'Tk',
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    // 2. Instagram: Orange/pink gradient with "Ig"
    if (lower.contains('instagram')) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFD1D1D), Color(0xFFE1306C), Color(0xFF833AB4)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          'Ig',
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    // 3. Oruv: Cream box with green sailboat/shield icon
    if (lower.contains('oruv')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5DFD7), width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.sailing_rounded,
          size: 20,
          color: _emeraldGreen,
        ),
      );
    }

    // 4. Safari: Light blue tinted box with blue compass icon
    if (lower.contains('safari')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEBF4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD6E7FF), width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.explore_outlined,
          size: 21,
          color: Color(0xFF007AFF),
        ),
      );
    }

    // 5. Nike SNKRS: Red box with white "SNKRS"
    if (lower.contains('snkrs') || lower.contains('nike')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE52E2E),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          'SNKRS',
          style: GoogleFonts.inter(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      );
    }

    // Default Monogram
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
          color: _primaryText,
        ),
      ),
    );
  }

  // ─── AUTHORIZATION PROMPT ────────────────────────────────────────────────

  Widget _buildAuthorizationPrompt() {
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
            onTap: widget.onConnectScreenTime,
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
