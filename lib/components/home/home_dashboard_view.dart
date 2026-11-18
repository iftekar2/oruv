import 'package:flutter/material.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/components/home/deep_work_anchor_card.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rules_schedules_section.dart';
import 'package:oruv/services/schedule_service.dart';
import 'package:oruv/services/screen_time_service.dart';

class HomeDashboardView extends StatelessWidget {
  final LiveAnchorSnapshot snapshot;
  final DailyScreenTimeSnapshot? screenTimeSnapshot;
  final List<AppScreenTimeItem> topFiveApps;
  final String mostBlockedAppName;
  final int mostBlockedAppCount;
  final bool hasMostBlockedNativeToken;
  final bool isOnMindfulBreak;
  final int mindfulBreakRemainingSeconds;
  final int mindfulBreakTotalSeconds;
  final List<ScheduleRuleModel> rules;
  final VoidCallback onTakeMindfulBreak;
  final VoidCallback onAdjustAnchor;
  final VoidCallback onConnectScreenTime;
  final VoidCallback onSelectInsightsTab;
  final void Function(String ruleId, bool isActive) onRuleToggled;
  final void Function(ScheduleRuleModel rule) onRuleTap;
  final VoidCallback onViewAllRules;

  const HomeDashboardView({
    super.key,
    required this.snapshot,
    required this.screenTimeSnapshot,
    required this.topFiveApps,
    required this.mostBlockedAppName,
    required this.mostBlockedAppCount,
    required this.hasMostBlockedNativeToken,
    required this.isOnMindfulBreak,
    required this.mindfulBreakRemainingSeconds,
    required this.mindfulBreakTotalSeconds,
    required this.rules,
    required this.onTakeMindfulBreak,
    required this.onAdjustAnchor,
    required this.onConnectScreenTime,
    required this.onSelectInsightsTab,
    required this.onRuleToggled,
    required this.onRuleTap,
    required this.onViewAllRules,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature 1: Live Deep Work Anchor Card
          RepaintBoundary(
            child: DeepWorkAnchorCard(
              shieldLabel: snapshot.shieldLabel,
              title: snapshot.title,
              isAuthorized: screenTimeSnapshot?.isAuthorized ?? false,
              scheduleStart: snapshot.scheduleStart,
              scheduleEnd: snapshot.scheduleEnd,
              remainingCycleText: snapshot.remainingCycleText,
              progress: snapshot.progress,
              sessionRemaining: snapshot.activeRule != null
                  ? ScheduleRuleModel.formatDurationMinutes(
                      snapshot.activeRule!.currentCycleRemainingMinutes,
                    )
                  : '0m',
              protectedToday: snapshot.projectedTimeText,
              isSavingTime: snapshot.isSavingTime,
              projectedTimeText: snapshot.projectedTimeText,
              projectedLabel: snapshot.projectedLabel,
              mostBlockedAppName: mostBlockedAppName,
              mostBlockedAppCount: mostBlockedAppCount,
              hasMostBlockedNativeToken: hasMostBlockedNativeToken,
              screenTimeToday:
                  (screenTimeSnapshot?.totalMinutes != null &&
                      screenTimeSnapshot!.totalMinutes! > 0)
                  ? ScheduleRuleModel.formatDurationMinutes(
                      screenTimeSnapshot!.totalMinutes!,
                    )
                  : '0m',
              focusedDuration: snapshot.focusedDuration,
              focusScore: snapshot.focusScore,
              isOnBreak: isOnMindfulBreak,
              breakRemainingSeconds: mindfulBreakRemainingSeconds,
              breakTotalSeconds: mindfulBreakTotalSeconds,
              onTakeMindfulBreak: onTakeMindfulBreak,
              onAdjust: onAdjustAnchor,
            ),
          ),

          const SizedBox(height: 20),

          // Feature 2: Daily Screen Time Card (Middle of screen, above Rules & Schedules)
          DailyScreenTimeCard(
            isAuthorized: screenTimeSnapshot?.isAuthorized ?? false,
            useNativeIosReport:
                screenTimeSnapshot?.useNativeIosReport ?? false,
            totalMinutes: screenTimeSnapshot?.totalMinutes,
            apps: topFiveApps,
            onConnect: onConnectScreenTime,
            onTap: onSelectInsightsTab,
            onTapHeader: onSelectInsightsTab,
          ),

          const SizedBox(height: 26),

          // Feature 3: Rules & Schedules Section (Horizontal Row in Escalator Order)
          RepaintBoundary(
            child: RulesSchedulesSection(
              rules: ScheduleService.sortRulesForHomeEscalator(rules),
              onRuleToggled: onRuleToggled,
              onRuleTap: onRuleTap,
              onViewAll: onViewAllRules,
              isGrid: false,
            ),
          ),
        ],
      ),
    );
  }
}
