import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';

class DailyScreenTimeSnapshot {
  /// Whether the user granted Screen Time (iOS) / Usage Access (Android).
  final bool isAuthorized;

  /// Real total minutes for today. Null when the OS did not provide data.
  final int? totalMinutes;

  /// Real total minutes for yesterday. Null when the OS did not provide data.
  final int? yesterdayMinutes;

  /// Real pickups per hour for today.
  final int? pickupsPerHour;

  /// Real per-app usage for today. Never fabricated.
  final List<AppScreenTimeItem> apps;

  /// On iOS, Apple only exposes real usage data inside a
  /// `DeviceActivityReport` extension, so the card must embed that native view.
  final bool useNativeIosReport;

  const DailyScreenTimeSnapshot({
    required this.isAuthorized,
    this.totalMinutes,
    this.yesterdayMinutes,
    this.pickupsPerHour,
    this.apps = const [],
    this.useNativeIosReport = false,
  });

  static const unavailable = DailyScreenTimeSnapshot(isAuthorized: false);
}

class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel('oruv/screen_time');

  static const Color _coralPink = Color(0xFFF26879);
  static const Color _emeraldGreen = Color(0xFF1D6F58);

  static const List<String> _distractingKeywords = [
    'tiktok', 'musically', 'aweme', 'instagram', 'burbn', 'snapchat', 'picaboo',
    'twitter', 'tweetie', 'atebits', 'reddit', 'facebook', 'threads', 'barcelona',
    'discord', 'pinterest', 'tumblr', 'bereal', 'bluesky', 'bsky', 'mastodon',
    'yikyak', 'fizz', 'linkedin', 'wechat', 'kik', 'telegram', 'whatsapp', 'messenger',
    'hinge', 'tinder', 'bumble',
    'youtube', 'netflix', 'twitch', 'hulu', 'disney', 'hbomax', 'wbd.stream',
    'primevideo', 'crunchyroll', 'peacock', 'paramount', 'tubi', 'plutotv',
    'kick', '9gag', 'ifunny', 'bilibili', 'dailymotion', 'webtoon',
    'roblox', 'minecraft', 'brawlstars', 'clashroyale', 'clashofclans', 'supercell',
    'candycrush', 'king.', 'genshin', 'hoyoverse', 'honkai', 'pubg', 'callofduty',
    'activision', 'fifa', 'madden', 'nba2k', 'amongus', 'innersloth',
    'subwaysurfers', 'pokemon', 'niantic', 'monopoly', 'scopely',
    'royalmatch', 'dreamgames', 'chess', 'steam', 'playstation', 'xbox', 'epicgames',
    'fortnite', 'riotgames', 'hearthstone', 'blizzard', 'zynga', 'rovio', 'angrybirds',
    'miniclip', 'playrix', 'gardenscapes', 'homescapes', 'blockblast', 'balatro', 'wordle',
  ];

  static bool isDistractingApp({required String name, String id = ''}) {
    final lowerName = name.toLowerCase().trim();
    final lowerId = id.toLowerCase().trim();
    if (lowerName.contains('oruv') || lowerId.contains('oruv')) {
      return false;
    }
    if (lowerName == 'x') return true;
    for (final kw in _distractingKeywords) {
      if (lowerName.contains(kw) || lowerId.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Fetches today's REAL screen time.
  ///
  /// - iOS: returns `useNativeIosReport: true` when authorized. The actual
  ///   numbers + icons are rendered by the `ScreenTimeReportExtension`
  ///   (Apple does not allow the main app to read usage minutes).
  /// - Android: queries `UsageStatsManager` + `PackageManager` for real
  ///   durations, categories, pickups, and real app icons.
  static Future<DailyScreenTimeSnapshot> fetchDailyScreenTime({
    int maxApps = 100,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return DailyScreenTimeSnapshot.unavailable;
    }

    try {
      if (Platform.isIOS) {
        final res = await _channel
            .invokeMapMethod<String, dynamic>('getDailyScreenTime');
        final authorized = res?['authorized'] == true;
        if (!authorized) return DailyScreenTimeSnapshot.unavailable;

        final rawTotal = (res?['totalMinutes'] as num?)?.toInt() ?? 0;
        final rawYesterday = (res?['yesterdayTotalMinutes'] as num?)?.toInt();
        final rawPickups = (res?['pickupsPerHour'] as num?)?.toInt();
        final rawApps = res?['apps'];
        final parsedApps = <AppScreenTimeItem>[];

        if (rawApps is List) {
          for (int i = 0; i < rawApps.length; i++) {
            final entry = rawApps[i];
            if (entry is! Map) continue;
            final map = Map<String, dynamic>.from(entry);
            final name = (map['name'] ?? 'App').toString();
            final id = (map['id'] ?? 'ios_app_$i').toString();
            final isDistracting = map['isDistracting'] == true ||
                isDistractingApp(name: name, id: id);
            final mins = (map['durationMinutes'] as num?)?.toInt() ?? 0;

            parsedApps.add(
              AppScreenTimeItem(
                id: id,
                name: name,
                durationMinutes: mins,
                barColor: isDistracting ? _coralPink : _emeraldGreen,
                isDistracting: isDistracting,
              ),
            );
          }
        }

        return DailyScreenTimeSnapshot(
          isAuthorized: true,
          totalMinutes: rawTotal,
          yesterdayMinutes: rawYesterday,
          pickupsPerHour: rawPickups,
          apps: parsedApps,
          useNativeIosReport: true,
        );
      }

      // Android
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getDailyScreenTime',
        {'maxApps': maxApps},
      );
      if (res == null) return DailyScreenTimeSnapshot.unavailable;

      final authorized = res['authorized'] == true;
      if (!authorized) return DailyScreenTimeSnapshot.unavailable;

      final rawTotal = (res['totalMinutes'] as num?)?.toInt() ?? 0;
      final rawYesterday = (res['yesterdayTotalMinutes'] as num?)?.toInt();
      final rawPickups = (res['pickupsPerHour'] as num?)?.toInt() ?? 0;
      final rawApps = res['apps'];
      final parsedApps = <AppScreenTimeItem>[];

      if (rawApps is List) {
        for (int i = 0; i < rawApps.length; i++) {
          final entry = rawApps[i];
          if (entry is! Map) continue;
          final map = Map<String, dynamic>.from(entry);
          final id = (map['id'] ?? 'app_$i').toString();
          final name = (map['name'] ?? 'App').toString();
          final isOwnApp = map['isOwnApp'] == true;
          final isDistracting = !isOwnApp &&
              (map['isDistracting'] == true ||
                  isDistractingApp(name: name, id: id));

          Uint8List? iconBytes;
          final rawBytes = map['iconBytes'];
          if (rawBytes is Uint8List) {
            iconBytes = rawBytes;
          } else if (rawBytes is List<int>) {
            iconBytes = Uint8List.fromList(rawBytes);
          }

          parsedApps.add(
            AppScreenTimeItem(
              id: id,
              name: name,
              durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
              barColor: isOwnApp ? _emeraldGreen : _coralPink,
              iconBytes: iconBytes,
              isDistracting: isDistracting,
            ),
          );
        }
      }

      return DailyScreenTimeSnapshot(
        isAuthorized: true,
        totalMinutes: rawTotal,
        yesterdayMinutes: rawYesterday,
        pickupsPerHour: rawPickups,
        apps: parsedApps,
      );
    } catch (e) {
      debugPrint('ScreenTimeService.fetchDailyScreenTime note: $e');
      return DailyScreenTimeSnapshot.unavailable;
    }
  }

  /// Queries native iOS Shield attempts for the most frequently blocked app today.
  static Future<Map<String, dynamic>> fetchBlockedAttempts() async {
    if (!Platform.isIOS) return {};
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('getBlockedAttempts');
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  /// Resets recorded blocked attempts for testing.
  static Future<void> resetBlockedAttempts() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('resetBlockedAttempts');
    } catch (_) {}
  }

  /// Requests Screen Time (iOS) or Usage Access (Android) permission.
  static Future<bool> requestAuthorization() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      final res = await _channel
          .invokeMapMethod<String, dynamic>('requestAuthorization');
      return res?['authorized'] == true;
    } catch (_) {
      return false;
    }
  }
}
