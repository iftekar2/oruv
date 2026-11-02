import 'package:flutter/material.dart';

class AppBadgeInfo {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const AppBadgeInfo({
    required this.label,
    required this.backgroundColor,
    this.textColor = const Color(0xFF1E1A1D),
  });
}

class BlockableAppOption {
  final String id;
  final String name;
  final String shortCode;
  final Color badgeColor;
  final IconData icon;

  const BlockableAppOption({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.badgeColor,
    required this.icon,
  });

  static const List<BlockableAppOption> catalog = [
    BlockableAppOption(
      id: 'instagram',
      name: 'Instagram',
      shortCode: 'IG',
      badgeColor: Color(0xFFFADCE4),
      icon: Icons.photo_camera_outlined,
    ),
    BlockableAppOption(
      id: 'tiktok',
      name: 'TikTok',
      shortCode: 'TT',
      badgeColor: Color(0xFFEBE7E5),
      icon: Icons.play_circle_outline_rounded,
    ),
    BlockableAppOption(
      id: 'x',
      name: 'X (Twitter)',
      shortCode: 'X',
      badgeColor: Color(0xFFECEEEF),
      icon: Icons.alternate_email_rounded,
    ),
    BlockableAppOption(
      id: 'youtube',
      name: 'YouTube',
      shortCode: 'YT',
      badgeColor: Color(0xFFFDE8B2),
      icon: Icons.smart_display_outlined,
    ),
    BlockableAppOption(
      id: 'reddit',
      name: 'Reddit',
      shortCode: 'RD',
      badgeColor: Color(0xFFFDF0E5),
      icon: Icons.forum_outlined,
    ),
    BlockableAppOption(
      id: 'snapchat',
      name: 'Snapchat',
      shortCode: 'SC',
      badgeColor: Color(0xFFFEF9C3),
      icon: Icons.chat_bubble_outline_rounded,
    ),
    BlockableAppOption(
      id: 'netflix',
      name: 'Netflix',
      shortCode: 'NF',
      badgeColor: Color(0xFFFEE2E2),
      icon: Icons.movie_outlined,
    ),
    BlockableAppOption(
      id: 'discord',
      name: 'Discord',
      shortCode: 'DC',
      badgeColor: Color(0xFFE0E7FF),
      icon: Icons.headset_mic_outlined,
    ),
    BlockableAppOption(
      id: 'twitch',
      name: 'Twitch',
      shortCode: 'TW',
      badgeColor: Color(0xFFF3E8FF),
      icon: Icons.videocam_outlined,
    ),
    BlockableAppOption(
      id: 'facebook',
      name: 'Facebook',
      shortCode: 'FB',
      badgeColor: Color(0xFFDBEAFE),
      icon: Icons.public_rounded,
    ),
  ];
}

class ScheduleRuleModel {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String enforcementMode;
  final bool isActive;
  final Set<String> activeDays;
  final Set<String> selectedAppIds;
  final int extraBlockedCount;

  const ScheduleRuleModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.enforcementMode,
    required this.isActive,
    this.activeDays = const {'M', 'T', 'W', 'T2', 'F'},
    this.selectedAppIds = const {'instagram', 'x', 'youtube'},
    this.extraBlockedCount = 0,
  });

  String get timeRange => '$startTime \u2013 $endTime';

  int get blockedCount => selectedAppIds.length + extraBlockedCount;

  /// Returns true only if this rule is toggled on (`isActive`) AND the current
  /// local time falls within [startTime] and [endTime].
  bool get isCurrentlyRunning {
    if (!isActive) return false;

    final startMins = _parseMinutesFromMidnight(startTime);
    final endMins = _parseMinutesFromMidnight(endTime);
    if (startMins == null || endMins == null) return false;

    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    if (startMins <= endMins) {
      return nowMins >= startMins && nowMins <= endMins;
    } else {
      // Overnight schedule (e.g. 9:30 PM - 7:00 AM)
      return nowMins >= startMins || nowMins <= endMins;
    }
  }

  static int? _parseMinutesFromMidnight(String formatted) {
    try {
      final clean = formatted.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final parts = clean
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim()
          .split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0].trim());
        final int minute = int.parse(parts[1].trim());
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        return hour * 60 + minute;
      }
    } catch (_) {}
    return null;
  }

  List<AppBadgeInfo> get badges {
    final selectedOptions = BlockableAppOption.catalog
        .where((opt) => selectedAppIds.contains(opt.id))
        .toList();

    final shown = selectedOptions.take(3).map((opt) {
      return AppBadgeInfo(
        label: opt.shortCode,
        backgroundColor: opt.badgeColor,
      );
    }).toList();

    final remaining = blockedCount - shown.length;
    if (remaining > 0) {
      shown.add(
        AppBadgeInfo(
          label: '+$remaining',
          backgroundColor: const Color(0xFFEDE8E5),
        ),
      );
    }
    return shown;
  }

  ScheduleRuleModel copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    String? enforcementMode,
    bool? isActive,
    Set<String>? activeDays,
    Set<String>? selectedAppIds,
    int? extraBlockedCount,
  }) {
    return ScheduleRuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enforcementMode: enforcementMode ?? this.enforcementMode,
      isActive: isActive ?? this.isActive,
      activeDays: activeDays ?? this.activeDays,
      selectedAppIds: selectedAppIds ?? this.selectedAppIds,
      extraBlockedCount: extraBlockedCount ?? this.extraBlockedCount,
    );
  }
}
