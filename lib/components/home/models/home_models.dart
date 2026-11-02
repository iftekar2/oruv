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

class ScheduleRuleModel {
  final String id;
  final String title;
  final String timeRange;
  final String enforcementMode;
  final bool isActive;
  final List<AppBadgeInfo> badges;
  final int blockedCount;

  const ScheduleRuleModel({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.enforcementMode,
    required this.isActive,
    required this.badges,
    required this.blockedCount,
  });

  ScheduleRuleModel copyWith({
    String? id,
    String? title,
    String? timeRange,
    String? enforcementMode,
    bool? isActive,
    List<AppBadgeInfo>? badges,
    int? blockedCount,
  }) {
    return ScheduleRuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      timeRange: timeRange ?? this.timeRange,
      enforcementMode: enforcementMode ?? this.enforcementMode,
      isActive: isActive ?? this.isActive,
      badges: badges ?? this.badges,
      blockedCount: blockedCount ?? this.blockedCount,
    );
  }
}
