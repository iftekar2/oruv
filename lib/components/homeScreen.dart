import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/adjust_anchor_sheet.dart';
import 'package:oruv/components/home/deep_work_anchor_card.dart';
import 'package:oruv/components/home/home_bottom_nav_bar.dart';
import 'package:oruv/components/home/home_top_app_bar.dart';
import 'package:oruv/components/home/mindful_break_sheet.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rule_editor_sheet.dart';
import 'package:oruv/components/home/rules_schedules_section.dart';
import 'package:oruv/components/home/shields_page.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/services/schedule_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  bool _isOnMindfulBreak = false;
  int _mindfulBreakRemainingSeconds = 0;
  int _mindfulBreakMinutesToday = 0;

  Timer? _liveClockTimer;
  Timer? _mindfulBreakTimer;

  List<ScheduleRuleModel> _rules = [];
  bool _isLoadingSchedules = true;

  @override
  void initState() {
    super.initState();
    _initializeDataAndShields();

    // Refresh live progress %, remaining time, and shield enforcement every 15s
    _liveClockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {});
      _syncShieldAndStats();
    });
  }

  Future<void> _initializeDataAndShields() async {
    await ScheduleService.refreshNativeSelectionCounts(
      onCountUpdated: (_) {
        if (mounted) {
          setState(() {});
          _syncShieldAndStats();
        }
      },
    );

    final loadedRules = await ScheduleService.loadSchedules();
    if (!mounted) return;

    setState(() {
      _rules = loadedRules;
      _isLoadingSchedules = false;
    });

    await _syncShieldAndStats();
  }

  Future<void> _syncShieldAndStats() async {
    await ScheduleService.syncNativeShield(
      rules: _rules,
      isOnMindfulBreak: _isOnMindfulBreak,
    );

    final snapshot = ScheduleService.computeLiveSnapshot(
      rules: _rules,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );

    await ScheduleService.syncDailyStats(
      snapshot: snapshot,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    _mindfulBreakTimer?.cancel();
    super.dispose();
  }

  void _handleTakeMindfulBreak() {
    if (_isOnMindfulBreak) {
      _mindfulBreakTimer?.cancel();
      setState(() {
        _isOnMindfulBreak = false;
        _mindfulBreakRemainingSeconds = 0;
      });
      _syncShieldAndStats();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MindfulBreakSheet(
        onStartBreakMinutes: (minutes) {
          _mindfulBreakTimer?.cancel();
          setState(() {
            _isOnMindfulBreak = true;
            _mindfulBreakRemainingSeconds = minutes * 60;
            _mindfulBreakMinutesToday += minutes;
          });
          _syncShieldAndStats();

          _mindfulBreakTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              if (!mounted) {
                timer.cancel();
                return;
              }
              if (_mindfulBreakRemainingSeconds <= 1) {
                timer.cancel();
                setState(() {
                  _isOnMindfulBreak = false;
                  _mindfulBreakRemainingSeconds = 0;
                });
                _syncShieldAndStats();
              } else {
                setState(() {
                  _mindfulBreakRemainingSeconds--;
                });
              }
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mindful break started for $minutes minutes \u2013 apps unlocked.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1D6F58),
            ),
          );
        },
      ),
    );
  }

  void _handleAdjustAnchor(LiveAnchorSnapshot snapshot) {
    final targetRule =
        snapshot.activeRule ?? snapshot.nextRule ?? (_rules.isNotEmpty ? _rules.first : null);

    final initialStart = targetRule?.startTime ?? '9:00 AM';
    final initialEnd = targetRule?.endTime ?? '5:00 PM';
    final initialStrict =
        targetRule?.enforcementMode == 'Strict enforcement mode';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AdjustAnchorSheet(
        initialStartTime: initialStart,
        initialEndTime: initialEnd,
        initialStrictLock: initialStrict,
        onSave: (start, end, strict) async {
          if (targetRule != null) {
            final updated = targetRule.copyWith(
              startTime: start,
              endTime: end,
              enforcementMode: strict
                  ? 'Strict enforcement mode'
                  : 'Balanced enforcement mode',
            );
            setState(() {
              _rules = _rules
                  .map((r) => r.id == updated.id ? updated : r)
                  .toList();
              OnboardingData.instance.scheduleStart = start;
              OnboardingData.instance.scheduleEnd = end;
              OnboardingData.instance.strictLock = strict;
            });
            await ScheduleService.upsertSchedule(updated, _rules);
            await _syncShieldAndStats();
          }
        },
      ),
    );
  }

  Future<void> _handleRuleToggled(String ruleId, bool isActive) async {
    ScheduleRuleModel? updatedRule;
    setState(() {
      _rules = _rules.map((r) {
        if (r.id == ruleId) {
          updatedRule = r.copyWith(isActive: isActive);
          return updatedRule!;
        }
        return r;
      }).toList();
    });

    if (updatedRule != null) {
      await ScheduleService.upsertSchedule(updatedRule!, _rules);
    }
    await _syncShieldAndStats();
  }

  void _openAddRuleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RuleEditorSheet(
        onSave: (newRule) async {
          setState(() {
            _rules = [newRule, ..._rules];
          });
          await ScheduleService.upsertSchedule(newRule, _rules);
          await _syncShieldAndStats();
        },
      ),
    );
  }

  void _openEditRuleSheet(ScheduleRuleModel rule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RuleEditorSheet(
        existingRule: rule,
        onSave: (updatedRule) async {
          setState(() {
            _rules = _rules.map((r) {
              if (r.id == updatedRule.id) {
                return updatedRule;
              }
              return r;
            }).toList();

            if (updatedRule.id == 'work_time') {
              OnboardingData.instance.scheduleStart = updatedRule.startTime;
              OnboardingData.instance.scheduleEnd = updatedRule.endTime;
            }
          });
          await ScheduleService.upsertSchedule(updatedRule, _rules);
          await _syncShieldAndStats();
        },
        onDelete: () async {
          setState(() {
            _rules = _rules.where((r) => r.id != rule.id).toList();
          });
          await ScheduleService.deleteSchedule(rule.id, _rules);
          await _syncShieldAndStats();
        },
      ),
    );
  }

  void _handleViewAllRules() {
    setState(() {
      _currentTabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ScheduleService.computeLiveSnapshot(
      rules: _rules,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HomeTopAppBar(),
      body: SafeArea(
        bottom: false,
        child: _isLoadingSchedules
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1D6F58),
                ),
              )
            : _buildActiveTabBody(snapshot),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildActiveTabBody(LiveAnchorSnapshot snapshot) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeDashboard(snapshot);
      case 1:
        return ShieldsPage(
          rules: _rules,
          onRuleToggled: _handleRuleToggled,
          onEditRule: _openEditRuleSheet,
          onAddRule: _openAddRuleSheet,
        );
      case 2:
        return _buildInsightsTabPlaceholder(snapshot);
      default:
        return _buildHomeDashboard(snapshot);
    }
  }

  Widget _buildHomeDashboard(LiveAnchorSnapshot snapshot) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature 1: Live Deep Work Anchor Card
          DeepWorkAnchorCard(
            shieldLabel: snapshot.shieldLabel,
            title: snapshot.title,
            scheduleStart: snapshot.scheduleStart,
            scheduleEnd: snapshot.scheduleEnd,
            remainingCycleText: snapshot.remainingCycleText,
            progress: snapshot.progress,
            focusedDuration: snapshot.focusedDuration,
            pickupsSaved: snapshot.pickupsSaved,
            focusScore: snapshot.focusScore,
            isOnBreak: _isOnMindfulBreak,
            onTakeMindfulBreak: _handleTakeMindfulBreak,
            onAdjust: () => _handleAdjustAnchor(snapshot),
          ),

          const SizedBox(height: 26),

          // Feature 2: Rules & Schedules Section (Horizontal Row)
          RulesSchedulesSection(
            rules: _rules,
            onRuleToggled: _handleRuleToggled,
            onRuleTap: _openEditRuleSheet,
            onViewAll: _handleViewAllRules,
            isGrid: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTabPlaceholder(LiveAnchorSnapshot snapshot) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Color(0xFF1D6F58),
            ),
            const SizedBox(height: 12),
            Text(
              'Focus Insights',
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${snapshot.focusedDuration} focused today \u2022 ${snapshot.pickupsSaved} pickups saved \u2022 ${snapshot.focusScore} Focus Score',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 13.5,
                color: const Color(0xFF6E6A6E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
