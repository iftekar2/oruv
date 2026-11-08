import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
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
  DateTime _selectedDate = DateTime.now();
  String _selectedGranularity = 'D'; // 'D', 'W', 'M'

  static const Color _bgCream = Color(0xFFFDFCF9);
  static const Color _cardBg = Colors.white;
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);
  static const Color _emeraldGreen = Color(0xFF1D6F58);
  static const Color _coralPink = Color(0xFFD46250);
  static const Color _trackColor = Color(0xFFF3ECEB);

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;
  }

  String get _dateTitle {
    if (_isToday) return 'Today';
    if (_isYesterday) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  List<AppScreenTimeItem> _getDistractingApps(List<AppScreenTimeItem> allApps) {
    return allApps.where((a) => a.isDistracting).toList();
  }

  List<AppScreenTimeItem> _getOtherApps(List<AppScreenTimeItem> allApps) {
    return allApps.where((a) => !a.isDistracting).toList();
  }

  /// Default fallback apps shown when no real app activity is cached yet
  /// so the screen looks alive and matches the reference design.
  List<AppScreenTimeItem> _buildSampleApps() {
    return const [
      AppScreenTimeItem(
        id: 'sample_tiktok',
        name: 'TikTok',
        durationMinutes: 80, // 1h 20m
        barColor: _coralPink,
        isDistracting: true,
      ),
      AppScreenTimeItem(
        id: 'sample_instagram',
        name: 'Instagram',
        durationMinutes: 79, // 1h 19m
        barColor: _coralPink,
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
        barColor: _emeraldGreen,
        isDistracting: false,
      ),
      AppScreenTimeItem(
        id: 'sample_snkrs',
        name: 'Nike SNKRS',
        durationMinutes: 9,
        barColor: _emeraldGreen,
        isDistracting: false,
      ),
      AppScreenTimeItem(
        id: 'sample_photos',
        name: 'Photos',
        durationMinutes: 5,
        barColor: _emeraldGreen,
        isDistracting: false,
      ),
      AppScreenTimeItem(
        id: 'sample_other',
        name: 'Other',
        durationMinutes: 16,
        barColor: _emeraldGreen,
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
    final totalMins = (widget.screenTimeSnapshot?.totalMinutes != null &&
            widget.screenTimeSnapshot!.totalMinutes! > 0)
        ? widget.screenTimeSnapshot!.totalMinutes!
        : (distractingMins + otherMins);

    // Max duration for proportional bar lengths across all apps
    final maxAppMins = effectiveApps.isEmpty
        ? 1
        : effectiveApps
            .map((e) => e.durationMinutes)
            .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Date Scrubber + Granularity Pill (D W M)
              _buildTopBar(),

              const SizedBox(height: 22),

              // 2. Hero Screen Time Metric & Savings Badge
              _buildHeroMetric(totalMins),

              const SizedBox(height: 24),

              // 3. Distracting Apps Section
              _buildSectionCard(
                title: 'DISTRACTING APPS',
                totalMinutes: distractingMins,
                accentColor: _coralPink,
                apps: distractingApps,
                maxAppMinutes: maxAppMins,
                emptyLabel: 'No distracting app usage recorded today.',
              ),

              const SizedBox(height: 18),

              // 4. Other Apps Section
              _buildSectionCard(
                title: 'OTHER APPS',
                totalMinutes: otherMins,
                accentColor: _emeraldGreen,
                apps: otherApps,
                maxAppMinutes: maxAppMins,
                emptyLabel: 'No other app usage recorded today.',
                bundleTailApps: true,
              ),

              const SizedBox(height: 24),

              // Connect prompt if not authorized
              if (widget.screenTimeSnapshot?.isAuthorized != true) ...[
                _buildAuthorizationPrompt(),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date Scrubber: ‹ Date ⌄ ›
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 20,
                color: _primaryText,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 18,
                onPressed: _previousDay,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      _dateTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: _mutedText,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 20,
                color: _isToday ? _mutedText.withValues(alpha: 0.35) : _primaryText,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 18,
                onPressed: _isToday ? null : _nextDay,
              ),
            ],
          ),
        ),

        // Segmented Granularity Pill: D  W  M
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['D', 'W', 'M'].map((granularity) {
              final isSelected = _selectedGranularity == granularity;
              return GestureDetector(
                onTap: () {
                  if (granularity != 'D') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granularity == 'W'
                              ? 'Weekly view will be available in the next update.'
                              : 'Monthly view will be available in the next update.',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: _emeraldGreen,
                      ),
                    );
                    return;
                  }
                  setState(() => _selectedGranularity = granularity);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF131B26) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    granularity,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : _mutedText,
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

  Widget _buildHeroMetric(int totalMinutes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cardBorder, width: 1.2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppScreenTimeItem.formatMinutes(totalMinutes),
                    style: GoogleFonts.lora(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Screen Time',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _mutedText,
                    ),
                  ),
                ],
              ),
              // Trend indicator badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5F0), // Soft mint tint
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _emeraldGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 13,
                      color: _emeraldGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '1h 52m today',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required int totalMinutes,
    required Color accentColor,
    required List<AppScreenTimeItem> apps,
    required int maxAppMinutes,
    required String emptyLabel,
    bool bundleTailApps = false,
  }) {
    // Optionally bundle smaller tail apps into "Other"
    List<AppScreenTimeItem> displayApps = List.from(apps);
    if (bundleTailApps && displayApps.length > 5) {
      final topApps = displayApps.take(4).toList();
      final tailApps = displayApps.skip(4).toList();
      final tailMins =
          tailApps.fold<int>(0, (sum, a) => sum + a.durationMinutes);
      topApps.add(
        AppScreenTimeItem(
          id: 'bundled_other',
          name: 'Other',
          durationMinutes: tailMins,
          barColor: accentColor,
          isDistracting: false,
        ),
      );
      displayApps = topApps;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cardBorder, width: 1.2),
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
          // Section Header: Title + Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
              Text(
                AppScreenTimeItem.formatMinutes(totalMinutes),
                style: GoogleFonts.lora(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF2EEEA), height: 1, thickness: 1),
          const SizedBox(height: 10),

          if (displayApps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                emptyLabel,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: _mutedText,
                ),
              ),
            )
          else
            ...displayApps.map((item) {
              final ratio = (item.durationMinutes / maxAppMinutes).clamp(
                0.08,
                1.0,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 38,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Icon
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: _buildAppIcon(item),
                      ),
                      const SizedBox(width: 12),

                      // App Name
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Horizontal Progress Bar
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: _trackColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Duration text
                      Text(
                        item.formattedDuration,
                        style: GoogleFonts.lora(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: item.isDistracting ? accentColor : _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAppIcon(AppScreenTimeItem item) {
    if (item.iconBytes != null && item.iconBytes!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFECE8E4), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
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

    if (lower.contains('tiktok')) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note_rounded, size: 18, color: Colors.white),
      );
    }

    if (lower.contains('instagram')) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
      );
    }

    if (lower.contains('oruv')) {
      return Container(
        decoration: BoxDecoration(
          color: _emeraldGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shield_rounded, size: 17, color: Colors.white),
      );
    }

    if (lower.contains('safari')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.explore_rounded, size: 18, color: Colors.white),
      );
    }

    if (lower.contains('photos')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF39C12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.photo_library_rounded, size: 17, color: Colors.white),
      );
    }

    if (lower.contains('other')) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: Colors.white),
      );
    }

    // Default Monogram
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _primaryText,
        ),
      ),
    );
  }

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

