import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppScreenTimeItem {
  final String id;
  final String name;
  final int durationMinutes;
  final Color barColor;

  /// Raw PNG bytes extracted dynamically from the OS (e.g., Android PackageManager).
  final Uint8List? iconBytes;

  /// Native iOS FamilyControls token index (renders real iOS icon & title via Label(token)).
  final int? iosTokenIndex;
  final bool isIosCategory;

  /// Optional custom widget icon override.
  final Widget? icon;

  const AppScreenTimeItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.barColor,
    this.iconBytes,
    this.iosTokenIndex,
    this.isIosCategory = false,
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

  /// Set to true once the `ScreenTimeReportExtension` target is enabled in Xcode
  /// to render Apple's system-wide `DeviceActivityReport` directly inside the card.
  final bool useIosDeviceActivityReport;

  const DailyScreenTimeCard({
    super.key,
    this.totalMinutes,
    this.apps,
    this.onTapHeader,
    this.useIosDeviceActivityReport = false,
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
      const AppScreenTimeItem(
        id: 'instagram',
        name: 'Instagram',
        durationMinutes: 88, // 1h 28m
        barColor: _coralPink,
      ),
      const AppScreenTimeItem(
        id: 'tiktok',
        name: 'TikTok',
        durationMinutes: 87, // 1h 27m
        barColor: _coralPink,
      ),
      AppScreenTimeItem(
        id: 'oruv',
        name: 'Oruv',
        durationMinutes: 65, // 1h 5m
        barColor: _emeraldGreen,
        icon: _buildAssetAppIcon(
          'lib/components/images/logo.png',
          isContain: true,
        ),
      ),
      const AppScreenTimeItem(
        id: 'youtube',
        name: 'YouTube',
        durationMinutes: 52, // 52m
        barColor: _coralPink,
      ),
      const AppScreenTimeItem(
        id: 'edits',
        name: 'Edits',
        durationMinutes: 14, // 14m
        barColor: Color(0xFF3BBA9C),
      ),
    ];
  }

  int get _effectiveTotalMinutes {
    if (totalMinutes != null && totalMinutes! > 0) return totalMinutes!;
    if (apps != null && apps!.isNotEmpty) {
      return apps!.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    }
    return 395; // 6h 35m preview fallback
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

          if (Platform.isIOS && useIosDeviceActivityReport) ...[
            const SizedBox(height: 8),
            const SizedBox(
              height: 320,
              child: UiKitView(
                viewType: 'oruv/device_activity_report',
                creationParamsCodec: StandardMessageCodec(),
              ),
            ),
          ] else ...[
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

            // List of apps with dynamic OS icons, names, horizontal bars, and times
            Column(
              children: appItems.map((item) {
                final ratio =
                    (item.durationMinutes / maxAppMinutes).clamp(0.08, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      // Dynamic OS App Icon (iOS FamilyControls token, Android PackageManager bytes, or fallback)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: _buildItemIcon(item),
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
                                Expanded(
                                  child: _buildItemTitle(item),
                                ),
                                const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  // --- Dynamic OS App Icon & Name Rendering ---

  static Widget _buildItemIcon(AppScreenTimeItem item) {
    // 1. Custom widget icon (e.g., Oruv logo)
    if (item.icon != null) {
      return item.icon!;
    }

    // 2. Native Android/OS icon bytes from PackageManager
    if (item.iconBytes != null && item.iconBytes!.isNotEmpty) {
      return _buildIconShell(
        child: Image.memory(
          item.iconBytes!,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildDefaultIcon(item.name),
        ),
      );
    }

    // 3. Native iOS Screen Time token icon via FamilyControls Label(token)
    if (Platform.isIOS && item.iosTokenIndex != null) {
      return _buildIconShell(
        child: IgnorePointer(
          child: UiKitView(
            key: ValueKey<String>(
              'ios_icon_${item.isIosCategory}_${item.iosTokenIndex}',
            ),
            viewType: 'oruv/app_token_icon',
            creationParams: <String, dynamic>{
              'index': item.iosTokenIndex,
              'isCategory': item.isIosCategory,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
      );
    }

    // 4. Clean monogram badge fallback for any unknown app
    return _buildDefaultIcon(item.name);
  }

  static Widget _buildItemTitle(AppScreenTimeItem item) {
    if (Platform.isIOS && item.iosTokenIndex != null) {
      return SizedBox(
        height: 19,
        child: IgnorePointer(
          child: UiKitView(
            key: ValueKey<String>(
              'ios_title_${item.isIosCategory}_${item.iosTokenIndex}',
            ),
            viewType: 'oruv/app_token_title',
            creationParams: <String, dynamic>{
              'index': item.iosTokenIndex,
              'isCategory': item.isIosCategory,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
      );
    }

    return Text(
      item.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.lora(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _primaryText,
      ),
    );
  }

  static Widget _buildIconShell({
    required Widget child,
    double padding = 0.0,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.5),
        border: Border.all(
          color: const Color(0xFFECE8E4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.5),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        ),
      ),
    );
  }

  static Widget _buildAssetAppIcon(String assetPath, {bool isContain = false}) {
    return _buildIconShell(
      padding: isContain ? 3.0 : 0.0,
      child: Image.asset(
        assetPath,
        width: 34,
        height: 34,
        fit: isContain ? BoxFit.contain : BoxFit.cover,
      ),
    );
  }

  static Widget _buildDefaultIcon(String name) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE7),
        borderRadius: BorderRadius.circular(8.5),
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
