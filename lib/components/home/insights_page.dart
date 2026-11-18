import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:oruv/components/home/insights/insights_app_breakdown.dart';
import 'package:oruv/components/home/insights/insights_authorization_card.dart';
import 'package:oruv/components/home/insights/insights_header.dart';
import 'package:oruv/components/home/insights/insights_metrics_card.dart';
import 'package:oruv/components/home/insights/insights_weekly_chart.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/services/screen_time_service.dart';

class InsightsPage extends StatefulWidget {
  final DailyScreenTimeSnapshot? screenTimeSnapshot;
  final String? timeSavedText;
  final VoidCallback? onConnectScreenTime;

  const InsightsPage({
    super.key,
    this.screenTimeSnapshot,
    this.timeSavedText,
    this.onConnectScreenTime,
  });

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String _selectedGranularity = 'D'; // 'D', 'W'

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _emeraldGreen = Color(0xFF16654E);
  static const Color _redBarColor = Color(0xFFE53935);

  List<AppScreenTimeItem> _getDistractingApps(List<AppScreenTimeItem> allApps) {
    return allApps
        .where(
          (a) =>
              a.isDistracting ||
              ScreenTimeService.isDistractingApp(name: a.name, id: a.id),
        )
        .toList();
  }

  List<AppScreenTimeItem> _getOtherApps(List<AppScreenTimeItem> allApps) {
    return allApps
        .where(
          (a) =>
              !a.isDistracting &&
              !ScreenTimeService.isDistractingApp(name: a.name, id: a.id),
        )
        .toList();
  }

  int _onboardingBaselineMinutes() {
    final choice = OnboardingData.instance.dailyScreenTime;
    if (choice == '< 2 hours') {
      return 120;
    } else if (choice == '3 - 4 hours') {
      return 240;
    } else if (choice == '5 - 6 hours') {
      return 360;
    } else if (choice == '7+ hours') {
      return 480;
    }
    return 300;
  }

  (String, String, bool) _computeDynamicTimeSaved(int totalMins) {
    final baselineMinutes = _onboardingBaselineMinutes();
    final yesterdayMins =
        widget.screenTimeSnapshot?.yesterdayMinutes != null &&
            widget.screenTimeSnapshot!.yesterdayMinutes! > 0
        ? widget.screenTimeSnapshot!.yesterdayMinutes!
        : baselineMinutes;

    final diff = yesterdayMins - totalMins;
    final isSavingTime = diff >= 0;
    final absDiff = diff.abs();
    final timeText = AppScreenTimeItem.formatMinutes(absDiff);
    final label = isSavingTime ? 'On Track to Save' : 'Over Yest.';
    return (timeText, label, isSavingTime);
  }

  (String, String, bool) _computeWeeklyGoalComparison(int dailyAvgMins) {
    final baselineMinutes = _onboardingBaselineMinutes();
    final diff = baselineMinutes - dailyAvgMins;
    final isUnderGoal = diff >= 0;
    final timeText = AppScreenTimeItem.formatMinutes(diff.abs());
    final label = isUnderGoal ? 'Under Daily Goal' : 'Over Daily Goal';
    return (timeText, label, isUnderGoal);
  }

  @override
  Widget build(BuildContext context) {
    final isAuthorized = widget.screenTimeSnapshot?.isAuthorized == true;

    // On iOS, Apple only exposes real per-app usage, real app icons, categories,
    // and pickups inside the DeviceActivityReport extension.
    if (Platform.isIOS && isAuthorized) {
      return const SizedBox.expand(
        child: UiKitView(
          viewType: 'oruv/insights_activity_report',
          creationParamsCodec: StandardMessageCodec(),
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
      );
    }

    final isWeek = _selectedGranularity == 'W';
    final effectiveApps = widget.screenTimeSnapshot?.apps ?? const [];

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
    final rawTotal = widget.screenTimeSnapshot?.totalMinutes ?? 0;
    final totalMins = math.max(rawTotal, distractingMins + otherMins);

    // Sunday-start week index: 0 = Sun, 1 = Mon, ..., 6 = Sat
    final todayIndex = DateTime.now().weekday % 7;
    final elapsedDays = todayIndex + 1;
    final yesterdayMins = widget.screenTimeSnapshot?.yesterdayMinutes ?? 0;

    final weekDayMinutes = List<int>.generate(7, (idx) {
      if (idx > todayIndex) return 0; // Future days have no data
      if (idx == todayIndex) return totalMins;
      if (idx == todayIndex - 1 && yesterdayMins > 0) return yesterdayMins;
      return 0;
    });
    final weekTotalMins = weekDayMinutes.fold<int>(0, (sum, m) => sum + m);
    final weekDailyAvgMins = (weekTotalMins / elapsedDays).round();

    final pctDistracted = totalMins > 0
        ? ((distractingMins / totalMins) * 100).round().clamp(0, 100)
        : 0;

    final maxAppMins = effectiveApps.isEmpty
        ? 1
        : effectiveApps
              .map((e) => e.durationMinutes)
              .reduce((a, b) => a > b ? a : b);

    final pickupsPerHour =
        widget.screenTimeSnapshot?.pickupsPerHour ?? (totalMins > 0 ? 1 : 0);
    final (timeSavedText, timeSavedLabel, isSavingTime) = isWeek
        ? _computeWeeklyGoalComparison(weekDailyAvgMins)
        : _computeDynamicTimeSaved(totalMins);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAuthorized) ...[
            InsightsAuthorizationCard(
              onConnect: widget.onConnectScreenTime,
            ),
            const SizedBox(height: 22),
          ],

          // ─── 1. TOP HERO: Screen Time / Daily Average + Switcher ─────
          InsightsHeroHeader(
            displayMinutes: isWeek ? weekDailyAvgMins : totalMins,
            isWeek: isWeek,
            selectedGranularity: _selectedGranularity,
            onGranularityChanged: (granularity) {
              setState(() => _selectedGranularity = granularity);
            },
          ),

          const SizedBox(height: 22),

          // ─── 2. WEEKLY BAR GRAPH (Week mode only) ────────────────────
          if (isWeek) ...[
            InsightsWeeklyChartCard(
              weekDayMinutes: weekDayMinutes,
              todayIndex: todayIndex,
              dailyAvgMinutes: weekDailyAvgMins,
              weekTotalMinutes: weekTotalMins,
            ),
            const SizedBox(height: 16),
          ],

          // ─── 3. 3-COLUMN METRICS SUMMARY CARD ────────────────────────
          InsightsMetricsCard(
            distractedPercentage: '$pctDistracted%',
            timeSavedDuration: timeSavedText,
            timeSavedLabel: timeSavedLabel,
            isSavingTime: isSavingTime,
            rightValue: isWeek ? '--' : '$pickupsPerHour',
            rightLabel: isWeek ? 'vs Last Week' : 'Pickups/HR',
            rightColor: _primaryText,
          ),

          const SizedBox(height: 26),

          // ─── 4. DISTRACTING APPS SECTION ─────────────────────────────
          InsightsSectionHeader(
            title: 'Distracting Apps',
            durationText: AppScreenTimeItem.formatMinutes(distractingMins),
          ),
          const SizedBox(height: 10),
          InsightsAppCard(
            apps: distractingApps,
            maxAppMinutes: maxAppMins,
            defaultBarColor: _redBarColor,
            emptyMessage: isWeek
                ? 'No distracting app activity recorded this week.'
                : 'No distracting app activity recorded today.',
          ),

          const SizedBox(height: 50),

          // ─── 5. OTHER APPS SECTION ───────────────────────────────────
          InsightsSectionHeader(
            title: 'Other Apps',
            durationText: AppScreenTimeItem.formatMinutes(otherMins),
          ),
          const SizedBox(height: 10),
          InsightsAppCard(
            apps: otherApps,
            maxAppMinutes: maxAppMins,
            defaultBarColor: _emeraldGreen,
            emptyMessage: isWeek
                ? 'No other app activity recorded this week.'
                : 'No other app activity recorded today.',
            isOtherSection: true,
          ),
        ],
      ),
    );
  }
}
