import 'dart:math' as math;
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

  static String weekdayKeyForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T2';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S2';
      default:
        return 'M';
    }
  }

  bool isScheduledForDay(DateTime date) {
    if (activeDays.isEmpty) return true;
    return activeDays.contains(weekdayKeyForDate(date));
  }

  /// Returns true only if this rule is toggled on (`isActive`), scheduled for
  /// today, AND the current local time falls within [startTime] and [endTime].
  bool get isCurrentlyRunning {
    if (!isActive) return false;
    final now = DateTime.now();
    if (!isScheduledForDay(now)) return false;

    final startMins = parseMinutesFromMidnight(startTime);
    final endMins = parseMinutesFromMidnight(endTime);
    if (startMins == null || endMins == null) return false;

    final nowMins = now.hour * 60 + now.minute;

    if (startMins <= endMins) {
      return nowMins >= startMins && nowMins < endMins;
    } else {
      // Overnight schedule (e.g. 9:30 PM - 7:00 AM)
      return nowMins >= startMins || nowMins < endMins;
    }
  }

  /// Total duration of this schedule in minutes.
  int get totalDurationMinutes {
    final startMins = parseMinutesFromMidnight(startTime);
    final endMins = parseMinutesFromMidnight(endTime);
    if (startMins == null || endMins == null) return 0;

    if (startMins <= endMins) {
      return (endMins - startMins).clamp(1, 1440);
    } else {
      return ((1440 - startMins) + endMins).clamp(1, 1440);
    }
  }

  /// Elapsed minutes in the current cycle if currently running.
  int get currentCycleElapsedMinutes {
    if (!isCurrentlyRunning) return 0;
    final startMins = parseMinutesFromMidnight(startTime);
    if (startMins == null) return 0;

    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    if (nowMins >= startMins) {
      return nowMins - startMins;
    } else {
      return (1440 - startMins) + nowMins;
    }
  }

  /// Remaining minutes in the current cycle if currently running.
  int get currentCycleRemainingMinutes {
    if (!isCurrentlyRunning) return 0;
    return (totalDurationMinutes - currentCycleElapsedMinutes)
        .clamp(0, totalDurationMinutes);
  }

  /// Progress (0.0 to 1.0) of the current cycle.
  double get currentCycleProgress {
    if (!isCurrentlyRunning) return 0.0;
    final total = totalDurationMinutes;
    if (total <= 0) return 0.0;
    return (currentCycleElapsedMinutes / total).clamp(0.0, 1.0);
  }

  /// Total minutes focused today from this schedule (whether currently in-progress or completed earlier today).
  int get focusedMinutesToday {
    if (!isActive) return 0;
    if (blockedCount <= 0) return 0;
    final now = DateTime.now();

    final startMins = parseMinutesFromMidnight(startTime);
    final endMins = parseMinutesFromMidnight(endTime);
    if (startMins == null || endMins == null) return 0;

    final nowMins = now.hour * 60 + now.minute;

    if (startMins <= endMins) {
      if (!isScheduledForDay(now)) return 0;
      if (nowMins < startMins) return 0;
      if (nowMins >= endMins) return endMins - startMins;
      return nowMins - startMins;
    } else {
      // Overnight schedule (e.g. 8:00 PM - 6:00 AM)
      int total = 0;
      // Night portion (starts tonight at startMins):
      if (isScheduledForDay(now) && nowMins > startMins) {
        total += nowMins - startMins;
      }
      // Morning portion (started yesterday evening, runs up to endMins today):
      final yesterday = now.subtract(const Duration(days: 1));
      if (isScheduledForDay(yesterday)) {
        total += nowMins < endMins ? nowMins : endMins;
      }
      return total;
    }
  }

  static int? parseMinutesFromMidnight(String formatted) {
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

  static const List<String> orderedDayKeys = [
    'M',
    'T',
    'W',
    'T2',
    'F',
    'S',
    'S2',
  ];

  static String dayKeyToShortName(String key) {
    switch (key) {
      case 'M':
        return 'Mon';
      case 'T':
        return 'Tue';
      case 'W':
        return 'Wed';
      case 'T2':
        return 'Thu';
      case 'F':
        return 'Fri';
      case 'S':
        return 'Sat';
      case 'S2':
        return 'Sun';
      default:
        return key;
    }
  }

  static Map<int, List<List<int>>> _buildDailyIntervals({
    required int startMins,
    required int endMins,
    required Set<String> activeDays,
  }) {
    final intervals = <int, List<List<int>>>{};
    for (int i = 0; i < 7; i++) {
      intervals[i] = [];
    }

    final effectiveDays = activeDays.isEmpty
        ? orderedDayKeys.toSet()
        : activeDays;

    for (int i = 0; i < orderedDayKeys.length; i++) {
      final key = orderedDayKeys[i];
      if (!effectiveDays.contains(key)) continue;

      if (startMins <= endMins) {
        // Same-day schedule: [startMins, endMins)
        intervals[i]!.add([startMins, endMins]);
      } else {
        // Overnight schedule: evening portion on day i, morning portion on day (i + 1) % 7
        intervals[i]!.add([startMins, 1440]);
        final nextDay = (i + 1) % 7;
        intervals[nextDay]!.add([0, endMins]);
      }
    }
    return intervals;
  }

  /// Checks if two sets of time windows and active days overlap.
  static bool checkTimeOverlap({
    required String startTime1,
    required String endTime1,
    required Set<String> activeDays1,
    required String startTime2,
    required String endTime2,
    required Set<String> activeDays2,
  }) {
    final s1 = parseMinutesFromMidnight(startTime1);
    final e1 = parseMinutesFromMidnight(endTime1);
    final s2 = parseMinutesFromMidnight(startTime2);
    final e2 = parseMinutesFromMidnight(endTime2);

    if (s1 == null || e1 == null || s2 == null || e2 == null) return false;

    final intervals1 = _buildDailyIntervals(
      startMins: s1,
      endMins: e1,
      activeDays: activeDays1,
    );
    final intervals2 = _buildDailyIntervals(
      startMins: s2,
      endMins: e2,
      activeDays: activeDays2,
    );

    for (int day = 0; day < 7; day++) {
      final list1 = intervals1[day] ?? [];
      final list2 = intervals2[day] ?? [];
      for (final int1 in list1) {
        for (final int2 in list2) {
          final overlapStart = math.max(int1[0], int2[0]);
          final overlapEnd = math.min(int1[1], int2[1]);
          if (overlapStart < overlapEnd) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Returns the first schedule in [existingRules] that overlaps with the given time and days,
  /// optionally excluding a rule by [excludeRuleId].
  static ScheduleRuleModel? findConflictingSchedule({
    required String startTime,
    required String endTime,
    required Set<String> activeDays,
    required List<ScheduleRuleModel> existingRules,
    String? excludeRuleId,
  }) {
    for (final rule in existingRules) {
      if (excludeRuleId != null && rule.id == excludeRuleId) continue;
      final overlaps = checkTimeOverlap(
        startTime1: startTime,
        endTime1: endTime,
        activeDays1: activeDays,
        startTime2: rule.startTime,
        endTime2: rule.endTime,
        activeDays2: rule.activeDays,
      );
      if (overlaps) {
        return rule;
      }
    }
    return null;
  }

  /// Returns true if this schedule overlaps in time and day with [other].
  bool overlapsWith(ScheduleRuleModel other) {
    return checkTimeOverlap(
      startTime1: startTime,
      endTime1: endTime,
      activeDays1: activeDays,
      startTime2: other.startTime,
      endTime2: other.endTime,
      activeDays2: other.activeDays,
    );
  }

  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  List<AppBadgeInfo> get badges {
    var selectedOptions = BlockableAppOption.catalog
        .where((opt) => selectedAppIds.contains(opt.id))
        .toList();

    if (selectedOptions.isEmpty && blockedCount > 0) {
      selectedOptions = BlockableAppOption.catalog
          .take(blockedCount.clamp(0, 3))
          .toList();
    }

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

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'active_days': activeDays.toList(),
      'enforcement_mode': enforcementMode,
      'is_active': isActive,
      'selected_app_ids': selectedAppIds.toList(),
      'extra_blocked_count': extraBlockedCount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'active_days': activeDays.toList(),
      'enforcement_mode': enforcementMode,
      'is_active': isActive,
      'selected_app_ids': selectedAppIds.toList(),
      'extra_blocked_count': extraBlockedCount,
    };
  }

  factory ScheduleRuleModel.fromMap(Map<String, dynamic> map) {
    final rawDays = map['active_days'];
    final Set<String> parsedDays = rawDays is List
        ? rawDays.map((e) => e.toString()).toSet()
        : {'M', 'T', 'W', 'T2', 'F'};

    final rawApps = map['selected_app_ids'];
    final Set<String> parsedApps = rawApps is List
        ? rawApps.map((e) => e.toString()).toSet()
        : {'instagram', 'x', 'youtube'};

    return ScheduleRuleModel(
      id: (map['id'] ?? 'rule_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      title: (map['title'] ?? 'Focus Schedule').toString(),
      startTime: (map['start_time'] ?? '9:00 AM').toString(),
      endTime: (map['end_time'] ?? '5:00 PM').toString(),
      enforcementMode:
          (map['enforcement_mode'] ?? 'Strict enforcement mode').toString(),
      isActive: map['is_active'] != false,
      activeDays: parsedDays,
      selectedAppIds: parsedApps,
      extraBlockedCount: (map['extra_blocked_count'] as num?)?.toInt() ?? 0,
    );
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

class LiveAnchorSnapshot {
  final ScheduleRuleModel? activeRule;
  final ScheduleRuleModel? nextRule;
  final String shieldLabel;
  final String title;
  final String scheduleStart;
  final String scheduleEnd;
  final String remainingCycleText;
  final double progress;
  final String focusedDuration;
  final int focusedMinutes;
  final int pickupsSaved;
  final int focusScore;
  final bool isSavingTime;
  final int projectedDiffMinutes;
  final String projectedTimeText;
  final String projectedLabel;
  final String shieldDiffFormatted;

  const LiveAnchorSnapshot({
    this.activeRule,
    this.nextRule,
    required this.shieldLabel,
    required this.title,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.remainingCycleText,
    required this.progress,
    required this.focusedDuration,
    required this.focusedMinutes,
    this.pickupsSaved = 0,
    required this.focusScore,
    this.isSavingTime = true,
    this.projectedDiffMinutes = 65,
    this.projectedTimeText = '1h 05m',
    this.projectedLabel = 'On Track to Save',
    this.shieldDiffFormatted = '↓ 1h 05m',
  });
}
