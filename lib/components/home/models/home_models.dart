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

enum ShieldedAppIconType {
  instagram,
  tiktok,
  x,
  youtube,
  reddit,
  snapchat,
}

class ShieldedAppModel {
  final String id;
  final String name;
  final ShieldedAppIconType iconType;
  final Color backgroundColor;
  final Color iconColor;
  final bool isLocked;

  const ShieldedAppModel({
    required this.id,
    required this.name,
    required this.iconType,
    required this.backgroundColor,
    required this.iconColor,
    this.isLocked = true,
  });

  ShieldedAppModel copyWith({
    String? id,
    String? name,
    ShieldedAppIconType? iconType,
    Color? backgroundColor,
    Color? iconColor,
    bool? isLocked,
  }) {
    return ShieldedAppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconType: iconType ?? this.iconType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

