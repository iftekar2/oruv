import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleService {
  static const MethodChannel _screenTimeChannel =
      MethodChannel('oruv/screen_time');
  static String? _lastNativeShieldSignature;
  static String? _lastDailyStatsSignature;

  /// Invalidates in-memory shield and daily-stats dedup signatures across
  /// logout, account deletion, or account switches.
  static void resetLocalCaches() {
    _lastNativeShieldSignature = null;
    _lastDailyStatsSignature = null;
  }

  /// Syncs native iOS Screen Time app shielding based on whether any schedule
  /// is currently running and the user is not on a mindful break.
  static Future<void> syncNativeShield({
    required List<ScheduleRuleModel> rules,
    required bool isOnMindfulBreak,
    DateTime? breakEndTime,
    int? breakDurationMinutes,
    String? sessionRemaining,
    String? protectedToday,
    String? screenTimeToday,
    String? scheduleTitle,
    String? projectedTimeText,
    String? projectedLabel,
    bool? isSavingTime,
  }) async {
    if (!Platform.isIOS) return;

    final effectiveIsOnBreak = isOnMindfulBreak &&
        (breakEndTime == null || DateTime.now().isBefore(breakEndTime));

    final hasActiveRunningSchedule =
        !effectiveIsOnBreak && rules.any((r) => r.isCurrentlyRunning);

    int baselineMinutes = 300;
    final onboardingChoice = OnboardingData.instance.dailyScreenTime;
    if (onboardingChoice == '< 2 hours') {
      baselineMinutes = 120;
    } else if (onboardingChoice == '3 - 4 hours') {
      baselineMinutes = 240;
    } else if (onboardingChoice == '5 - 6 hours') {
      baselineMinutes = 360;
    } else if (onboardingChoice == '7+ hours') {
      baselineMinutes = 480;
    }

    String? currentUserId;
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}

    final breakEndTimeMs = effectiveIsOnBreak && breakEndTime != null
        ? breakEndTime.millisecondsSinceEpoch.toDouble()
        : null;

    final signature =
        '${currentUserId ?? 'anon'}|$hasActiveRunningSchedule|$effectiveIsOnBreak|$breakEndTimeMs|$baselineMinutes|$sessionRemaining|$protectedToday|$screenTimeToday|$scheduleTitle|$projectedTimeText|$projectedLabel|$isSavingTime';
    if (_lastNativeShieldSignature == signature) {
      return;
    }
    _lastNativeShieldSignature = signature;

    try {
      await _screenTimeChannel.invokeMethod('syncShield', {
        'shouldBlock': hasActiveRunningSchedule,
        'baselineMinutes': baselineMinutes,
        if (breakEndTimeMs != null) 'breakEndTimeMs': breakEndTimeMs,
        if (breakDurationMinutes != null)
          'breakDurationMinutes': breakDurationMinutes,
        if (sessionRemaining != null) 'sessionRemaining': sessionRemaining,
        if (protectedToday != null) 'protectedToday': protectedToday,
        if (screenTimeToday != null) 'screenTimeToday': screenTimeToday,
        if (scheduleTitle != null) 'scheduleTitle': scheduleTitle,
        if (projectedTimeText != null) 'projectedTimeText': projectedTimeText,
        if (projectedLabel != null) 'projectedLabel': projectedLabel,
        if (isSavingTime != null) 'isSavingTime': isSavingTime,
      });
    } catch (e) {
      debugPrint('Native syncShield note: $e');
    }
  }

  /// Queries native iOS Screen Time authorization and current selection counts.
  static Future<int> refreshNativeSelectionCounts({
    ValueChanged<int>? onCountUpdated,
  }) async {
    if (!Platform.isIOS) {
      return OnboardingData.instance.totalSelectedAppsCount;
    }

    _screenTimeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSelectionChanged') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          OnboardingData.instance.nativeSelectedAppsCount =
              (args['appsCount'] as int?) ?? 0;
          OnboardingData.instance.nativeSelectedCategoriesCount =
              (args['categoriesCount'] as int?) ?? 0;
          OnboardingData.instance.nativeSelectedDomainsCount =
              (args['domainsCount'] as int?) ?? 0;
          onCountUpdated?.call(OnboardingData.instance.totalSelectedAppsCount);
        }
      }
    });

    try {
      final res = await _screenTimeChannel
          .invokeMapMethod<String, dynamic>('checkAuthorizationStatus');
      if (res?['authorized'] == true) {
        OnboardingData.instance.screenTimeAuthorized = true;
      }
    } catch (_) {}

    return OnboardingData.instance.totalSelectedAppsCount;
  }

  /// Loads schedules for the authenticated user from Supabase `focus_schedules`
  /// (falling back to `user_metadata` or default schedules if none exist yet).
  static Future<List<ScheduleRuleModel>> loadSchedules() async {
    final defaultRules = _buildDefaultRules();

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return defaultRules;

      // 1. Try loading from `public.focus_schedules` table
      try {
        final rows = await client
            .from('focus_schedules')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 4));

        if (rows.isNotEmpty) {
          final loaded = rows
              .map<ScheduleRuleModel>(
                (row) => ScheduleRuleModel.fromMap(
                  Map<String, dynamic>.from(row as Map),
                ),
              )
              .toList();
          return _migrateLegacyDefaultScheduleTimes(loaded);
        }
      } catch (e) {
        debugPrint('focus_schedules select note: $e');
      }

      // 2. Fallback: Check user_metadata['focus_schedules']
      final metaSchedules = user.userMetadata?['focus_schedules'];
      if (metaSchedules is List && metaSchedules.isNotEmpty) {
        final loaded = metaSchedules
            .whereType<Map>()
            .map(
              (m) => ScheduleRuleModel.fromMap(Map<String, dynamic>.from(m)),
            )
            .toList();
        if (loaded.isNotEmpty) {
          final migrated = _migrateLegacyDefaultScheduleTimes(loaded);
          // Seed table in background if table now exists
          _seedSchedulesToTable(user.id, migrated);
          return migrated;
        }
      }

      // 3. First time: seed default rules into Supabase
      await saveAllSchedules(defaultRules);
      return defaultRules;
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      return defaultRules;
    }
  }

  static Future<void> _seedSchedulesToTable(
    String userId,
    List<ScheduleRuleModel> rules,
  ) async {
    try {
      final client = Supabase.instance.client;
      final payload = rules.map((r) => r.toSupabaseMap(userId)).toList();
      await client
          .from('focus_schedules')
          .upsert(payload, onConflict: 'user_id,id');
    } catch (e) {
      debugPrint('focus_schedules seed note: $e');
    }
  }

  /// Saves or updates a single schedule in Supabase and mirrors the list to metadata.
  static Future<void> upsertSchedule(
    ScheduleRuleModel rule,
    List<ScheduleRuleModel> allRules,
  ) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      try {
        await client
            .from('focus_schedules')
            .upsert(rule.toSupabaseMap(user.id), onConflict: 'user_id,id');
      } catch (e) {
        debugPrint('focus_schedules upsert note: $e');
      }

      await _mirrorSchedulesToMetadata(allRules);
    } catch (e) {
      debugPrint('upsertSchedule error: $e');
    }
  }

  /// Deletes a schedule from Supabase `focus_schedules` and updates metadata.
  static Future<void> deleteSchedule(
    String ruleId,
    List<ScheduleRuleModel> remainingRules,
  ) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      try {
        await client
            .from('focus_schedules')
            .delete()
            .eq('id', ruleId)
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('focus_schedules delete note: $e');
      }

      await _mirrorSchedulesToMetadata(remainingRules);
    } catch (e) {
      debugPrint('deleteSchedule error: $e');
    }
  }

  /// Saves all schedules to Supabase `focus_schedules` and `user_metadata`.
  static Future<void> saveAllSchedules(List<ScheduleRuleModel> rules) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      try {
        if (rules.isNotEmpty) {
          final payload = rules.map((r) => r.toSupabaseMap(user.id)).toList();
          await client
              .from('focus_schedules')
              .upsert(payload, onConflict: 'user_id,id');
        }
      } catch (e) {
        debugPrint('focus_schedules bulk upsert note: $e');
      }

      await _mirrorSchedulesToMetadata(rules);
    } catch (e) {
      debugPrint('saveAllSchedules error: $e');
    }
  }

  static Future<void> _mirrorSchedulesToMetadata(
    List<ScheduleRuleModel> rules,
  ) async {
    try {
      final client = Supabase.instance.client;
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'focus_schedules': rules.map((r) => r.toJsonMap()).toList(),
          },
        ),
      );
    } catch (_) {}
  }

  /// Sorts schedules like an escalator for the Home page:
  /// 1. Currently running schedule(s) first
  /// 2. Upcoming enabled schedules next (ordered by soonest start time)
  /// 3. Schedules that have already passed today move to the back
  /// 4. Toggled-off schedules last
  static List<ScheduleRuleModel> sortRulesForHomeEscalator(
    List<ScheduleRuleModel> rules,
  ) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    int minutesUntilNextStart(ScheduleRuleModel rule) {
      final startMins =
          ScheduleRuleModel.parseMinutesFromMidnight(rule.startTime) ?? 0;
      if (startMins > nowMins) {
        return startMins - nowMins;
      } else {
        // Already passed earlier today -> wraps around to tomorrow
        return (1440 - nowMins) + startMins;
      }
    }

    final sorted = List<ScheduleRuleModel>.from(rules);
    sorted.sort((a, b) {
      final aRunning = a.isCurrentlyRunning;
      final bRunning = b.isCurrentlyRunning;
      if (aRunning != bRunning) {
        return aRunning ? -1 : 1;
      }

      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }

      if (aRunning && bRunning) {
        return a.currentCycleRemainingMinutes
            .compareTo(b.currentCycleRemainingMinutes);
      }

      return minutesUntilNextStart(a).compareTo(minutesUntilNextStart(b));
    });

    return sorted;
  }

  /// Computes real, live metrics for the top Deep Work Anchor card from the
  /// user's schedules and current time of day.
  static LiveAnchorSnapshot computeLiveSnapshot({
    required List<ScheduleRuleModel> rules,
    required int mindfulBreakMinutesToday,
    int? todayScreenTimeMinutes,
    int? yesterdayScreenTimeMinutes,
    String? timeSavedText,
    String? timeSavedLabel,
    bool? isSavingTimeOverride,
  }) {
    final escalatorRules = sortRulesForHomeEscalator(rules);

    ScheduleRuleModel? activeRule;
    for (final rule in escalatorRules) {
      if (rule.isCurrentlyRunning) {
        activeRule = rule;
        break;
      }
    }

    ScheduleRuleModel? nextRule;
    if (activeRule == null) {
      final enabledRules = escalatorRules.where((r) => r.isActive).toList();
      if (enabledRules.isNotEmpty) {
        nextRule = enabledRules.first;
      } else if (escalatorRules.isNotEmpty) {
        nextRule = escalatorRules.first;
      }
    }

    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    // Track unique minutes of today [0..nowMins] where apps were actually blocked
    final shieldedMinutes = <int>{};

    for (final rule in rules) {
      if (!rule.isActive || rule.blockedCount <= 0) continue;

      final startMins =
          ScheduleRuleModel.parseMinutesFromMidnight(rule.startTime);
      final endMins =
          ScheduleRuleModel.parseMinutesFromMidnight(rule.endTime);
      if (startMins == null || endMins == null) continue;

      if (startMins <= endMins) {
        // Daytime schedule (e.g. 6:30 AM - 8:30 AM or 9:00 AM - 5:00 PM)
        if (rule.isScheduledForDay(now)) {
          final effectiveEnd = nowMins < endMins ? nowMins : endMins;
          for (int m = startMins; m < effectiveEnd; m++) {
            shieldedMinutes.add(m);
          }
        }
      } else {
        // Overnight schedule (e.g. 8:00 PM - 7:00 AM)
        // Evening part (starts tonight at startMins):
        if (rule.isScheduledForDay(now) && nowMins > startMins) {
          for (int m = startMins; m < nowMins; m++) {
            shieldedMinutes.add(m);
          }
        }
        // Morning part (started yesterday evening, runs up to endMins today):
        final yesterday = now.subtract(const Duration(days: 1));
        if (rule.isScheduledForDay(yesterday)) {
          final morningEnd = nowMins < endMins ? nowMins : endMins;
          for (int m = 0; m < morningEnd; m++) {
            shieldedMinutes.add(m);
          }
        }
      }
    }

    final focusedMinutes = (shieldedMinutes.length - mindfulBreakMinutesToday)
        .clamp(0, 1440);
    final focusedDuration =
        ScheduleRuleModel.formatDurationMinutes(focusedMinutes);

    // Focus Score (0 - 100): starts at base 75 when rules are enabled, scales up with focused time
    final enabledCount = rules.where((r) => r.isActive).length;
    int focusScore = 0;
    if (enabledCount > 0) {
      final bonusFromFocus = (focusedMinutes / 18).round().clamp(0, 25);
      focusScore = (75 + bonusFromFocus).clamp(0, 100);
    }

    // -------------------------------------------------------------
    // Screen Time Reclaimed (Yesterday vs. Today) - Matching Insights Page
    // -------------------------------------------------------------
    // 1. Yesterday's baseline screen time in minutes:
    int yesterdayBaselineMinutes = 300; // default 5 hours fallback matching Insights
    final onboardingChoice = OnboardingData.instance.dailyScreenTime;
    if (onboardingChoice == '< 2 hours') {
      yesterdayBaselineMinutes = 120;
    } else if (onboardingChoice == '3 - 4 hours') {
      yesterdayBaselineMinutes = 240;
    } else if (onboardingChoice == '5 - 6 hours') {
      yesterdayBaselineMinutes = 360;
    } else if (onboardingChoice == '7+ hours') {
      yesterdayBaselineMinutes = 480;
    }

    final int netDiffMinutes;
    final bool isSavingTime;
    final String projectedTimeText;
    final String projectedLabel;

    if (timeSavedText != null && timeSavedText.isNotEmpty) {
      projectedTimeText = timeSavedText;
      if (timeSavedLabel != null &&
          (timeSavedLabel.toLowerCase().contains('over') ||
           timeSavedLabel.toLowerCase().contains('more'))) {
        isSavingTime = false;
      } else if (timeSavedLabel != null &&
          (timeSavedLabel.toLowerCase().contains('save') ||
           timeSavedLabel.toLowerCase().contains('less') ||
           timeSavedLabel.toLowerCase().contains('track'))) {
        isSavingTime = true;
      } else if (isSavingTimeOverride != null) {
        isSavingTime = isSavingTimeOverride;
      } else {
        isSavingTime = true;
      }
      projectedLabel = timeSavedLabel ??
          (isSavingTime ? 'On Track to Save' : 'Over Yest.');
      netDiffMinutes = 0;
    } else if (todayScreenTimeMinutes != null && todayScreenTimeMinutes > 0) {
      final effectiveYesterdayMinutes =
          (yesterdayScreenTimeMinutes != null && yesterdayScreenTimeMinutes > 0)
              ? yesterdayScreenTimeMinutes
              : yesterdayBaselineMinutes;

      // Direct comparison matching Insights page: yesterday minus today
      final diff = effectiveYesterdayMinutes - todayScreenTimeMinutes;
      isSavingTime = diff >= 0;
      netDiffMinutes = diff.abs();

      projectedTimeText =
          ScheduleRuleModel.formatDurationMinutes(netDiffMinutes);
      projectedLabel = isSavingTime
          ? 'On Track to Save'
          : 'Over Yest.';
    } else {
      isSavingTime = true;
      netDiffMinutes = 0;
      projectedTimeText = focusedDuration;
      projectedLabel = 'On Track to Save';
    }

    final int projectedDiffMinutes = netDiffMinutes;

    final String shieldDiffFormatted = isSavingTime
        ? '↓ $projectedTimeText'
        : '↑ $projectedTimeText';

    if (activeRule != null) {
      final remMins = activeRule.currentCycleRemainingMinutes;
      final remText =
          '${ScheduleRuleModel.formatDurationMinutes(remMins)} remaining in current cycle';

      return LiveAnchorSnapshot(
        activeRule: activeRule,
        nextRule: null,
        shieldLabel: '${activeRule.title} Shield',
        title: activeRule.title == 'Work Time'
            ? 'Deep Work Anchor'
            : activeRule.title,
        scheduleStart: activeRule.startTime,
        scheduleEnd: activeRule.endTime,
        remainingCycleText: remText,
        progress: activeRule.currentCycleProgress,
        focusedDuration: focusedDuration,
        focusedMinutes: focusedMinutes,
        pickupsSaved: 0,
        focusScore: focusScore,
        isSavingTime: isSavingTime,
        projectedDiffMinutes: projectedDiffMinutes,
        projectedTimeText: projectedTimeText,
        projectedLabel: projectedLabel,
        shieldDiffFormatted: shieldDiffFormatted,
      );
    } else if (nextRule != null) {
      return LiveAnchorSnapshot(
        activeRule: null,
        nextRule: nextRule,
        shieldLabel: nextRule.isActive ? 'Scheduled Shield' : 'Shield Paused',
        title: nextRule.title == 'Work Time'
            ? 'Deep Work Anchor'
            : nextRule.title,
        scheduleStart: nextRule.startTime,
        scheduleEnd: nextRule.endTime,
        remainingCycleText: nextRule.isActive
            ? 'Next cycle starts at ${nextRule.startTime}'
            : 'Schedule is currently toggled off',
        progress: 0.0,
        focusedDuration: focusedDuration,
        focusedMinutes: focusedMinutes,
        pickupsSaved: 0,
        focusScore: focusScore,
        isSavingTime: isSavingTime,
        projectedDiffMinutes: projectedDiffMinutes,
        projectedTimeText: projectedTimeText,
        projectedLabel: projectedLabel,
        shieldDiffFormatted: shieldDiffFormatted,
      );
    } else {
      return LiveAnchorSnapshot(
        activeRule: null,
        nextRule: null,
        shieldLabel: 'Work Time Shield',
        title: 'Deep Work Anchor',
        scheduleStart: '9:00 AM',
        scheduleEnd: '5:00 PM',
        remainingCycleText: 'No schedules configured yet',
        progress: 0.0,
        focusedDuration: '0m',
        focusedMinutes: 0,
        pickupsSaved: 0,
        focusScore: 0,
        isSavingTime: isSavingTime,
        projectedDiffMinutes: projectedDiffMinutes,
        projectedTimeText: projectedTimeText,
        projectedLabel: projectedLabel,
        shieldDiffFormatted: shieldDiffFormatted,
      );
    }
  }

  /// Syncs today's computed focus stats into `public.daily_focus_stats`.
  static Future<void> syncDailyStats({
    required LiveAnchorSnapshot snapshot,
    required int mindfulBreakMinutesToday,
  }) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final statsSignature =
          '${user.id}|$dateStr|${snapshot.focusedMinutes}|${snapshot.pickupsSaved}|${snapshot.focusScore}|$mindfulBreakMinutesToday';
      if (_lastDailyStatsSignature == statsSignature) {
        return;
      }
      _lastDailyStatsSignature = statsSignature;

      await client.from('daily_focus_stats').upsert(
        {
          'user_id': user.id,
          'stat_date': dateStr,
          'focused_minutes': snapshot.focusedMinutes,
          'pickups_saved': snapshot.pickupsSaved,
          'focus_score': snapshot.focusScore,
          'mindful_break_minutes': mindfulBreakMinutesToday,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,stat_date',
      );
    } catch (_) {}
  }

  static List<ScheduleRuleModel> _migrateLegacyDefaultScheduleTimes(
    List<ScheduleRuleModel> rules,
  ) {
    bool changed = false;
    final migrated = rules.map((rule) {
      if (rule.id == 'evening_wind_down' &&
          rule.startTime == '8:00 PM' &&
          rule.endTime == '7:00 AM') {
        changed = true;
        return rule.copyWith(endTime: '6:00 AM');
      }
      return rule;
    }).toList();

    if (changed) {
      saveAllSchedules(migrated);
    }
    return migrated;
  }

  static List<ScheduleRuleModel> _buildDefaultRules() {
    final start = OnboardingData.instance.scheduleStart.isNotEmpty
        ? OnboardingData.instance.scheduleStart
        : '9:00 AM';
    final end = OnboardingData.instance.scheduleEnd.isNotEmpty
        ? OnboardingData.instance.scheduleEnd
        : '5:00 PM';
    final strict = OnboardingData.instance.strictLock;
    final nativeCount = OnboardingData.instance.totalSelectedAppsCount;

    return [
      ScheduleRuleModel(
        id: 'work_time',
        title: 'Work Time',
        startTime: start,
        endTime: end,
        enforcementMode: strict
            ? 'Strict enforcement mode'
            : 'Balanced enforcement mode',
        isActive: true,
        activeDays: OnboardingData.instance.activeDays.isNotEmpty
            ? Set<String>.from(OnboardingData.instance.activeDays)
            : const {'M', 'T', 'W', 'T2', 'F'},
        selectedAppIds: const {},
        extraBlockedCount: nativeCount,
      ),
      ScheduleRuleModel(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        startTime: '8:00 PM',
        endTime: '6:00 AM',
        enforcementMode: 'Strict enforcement mode',
        isActive: false,
        selectedAppIds: const {},
        extraBlockedCount: nativeCount,
      ),
      ScheduleRuleModel(
        id: 'morning_clarity',
        title: 'Morning Clarity',
        startTime: '6:30 AM',
        endTime: '8:30 AM',
        enforcementMode: 'Gentle reminder mode',
        isActive: false,
        selectedAppIds: const {},
        extraBlockedCount: nativeCount,
      ),
    ];
  }
}

