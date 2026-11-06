import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppScreenTimeItem {
  final String id;
  final String name;
  final int durationMinutes;
  final Color barColor;

  /// Raw PNG bytes extracted from the OS (Android PackageManager).
  final Uint8List? iconBytes;

  const AppScreenTimeItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.barColor,
    this.iconBytes,
  });

  String get formattedDuration => formatMinutes(durationMinutes);

  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}

class DailyScreenTimeCard extends StatelessWidget {
  final bool isAuthorized;
  final bool useNativeIosReport;
  final int? totalMinutes;
  final List<AppScreenTimeItem> apps;
  final VoidCallback? onTapHeader;
  final VoidCallback? onConnect;

  const DailyScreenTimeCard({
    super.key,
    required this.isAuthorized,
    this.useNativeIosReport = false,
    this.totalMinutes,
    this.apps = const [],
    this.onTapHeader,
    this.onConnect,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);
  static const Color _emeraldGreen = Color(0xFF1D6F58);
  static const Color _trackColor = Color(0xFFF3ECEB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildHeader(),
          if (!isAuthorized)
            _buildConnectPrompt()
          else if (Platform.isIOS && useNativeIosReport)
            _buildIosNativeReport()
          else
            _buildFlutterReport(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
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
          const Icon(Icons.chevron_right_rounded, size: 18, color: _mutedText),
        ],
      ),
    );
  }

  /// iOS: Apple renders the real total, app icons, names and minutes.
  Widget _buildIosNativeReport() {
    return const Padding(
      padding: EdgeInsets.only(top: 6),
      child: SizedBox(
        // Total headline + "Today" + divider + up to 5 tucked-in rows.
        height: 276,
        child: Stack(
          children: [
            UiKitView(
              viewType: 'oruv/device_activity_report',
              creationParamsCodec: StandardMessageCodec(),
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Color(0x01FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Android: real data from UsageStatsManager.
  Widget _buildFlutterReport() {
    final total =
        totalMinutes ??
        apps.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    final maxAppMinutes = apps.isEmpty
        ? 1
        : apps.map((e) => e.durationMinutes).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          AppScreenTimeItem.formatMinutes(total),
          style: GoogleFonts.lora(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _primaryText,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Today',
          style: GoogleFonts.inter(fontSize: 12.5, color: _mutedText),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFF2EEEA), height: 1, thickness: 1),
        const SizedBox(height: 14),
        if (apps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No app usage recorded yet today.',
              style: GoogleFonts.lora(fontSize: 13, color: _mutedText),
            ),
          )
        else
          ...apps.map((item) {
            final ratio = (item.durationMinutes / maxAppMinutes).clamp(
              0.08,
              1.0,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: _buildItemIcon(item),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
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
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item.formattedDuration,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.barColor == _emeraldGreen
                            ? _emeraldGreen
                            : _primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildConnectPrompt() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Platform.isAndroid
                ? 'Allow Usage Access to see how much time you spend in each app today.'
                : 'Connect Screen Time to see how much time you spend in each app today.',
            style: GoogleFonts.lora(
              fontSize: 13.5,
              height: 1.4,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _emeraldGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Platform.isAndroid
                    ? 'Allow Usage Access'
                    : 'Connect Screen Time',
                style: GoogleFonts.inter(
                  fontSize: 13,
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

  static Widget _buildItemIcon(AppScreenTimeItem item) {
    if (item.iconBytes != null && item.iconBytes!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.5),
          border: Border.all(color: const Color(0xFFECE8E4), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7.5),
          child: Image.memory(
            item.iconBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _buildDefaultIcon(item.name),
          ),
        ),
      );
    }
    return _buildDefaultIcon(item.name);
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
