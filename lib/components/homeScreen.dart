import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/adjust_anchor_sheet.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
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
import 'package:oruv/services/screen_time_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentTabIndex = 0;

  bool _isOnMindfulBreak = false;
  int _mindfulBreakRemainingSeconds = 0;
  int _mindfulBreakTotalSeconds = 0;
  DateTime? _breakEndTime;
  int _mindfulBreakMinutesToday = 0;

  Timer? _liveClockTimer;
  Timer? _mindfulBreakTimer;

  List<ScheduleRuleModel> _rules = [];
  bool _isLoadingSchedules = true;
  DailyScreenTimeSnapshot? _screenTimeSnapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDataAndShields();

    // Refresh live progress %, remaining time, and shield enforcement every 15s
    _liveClockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {});
      _syncShieldAndStats();
    });
  }

  Future<void> _initializeDataAndShields() async {
    try {
      await ScheduleService.refreshNativeSelectionCounts(
        onCountUpdated: (_) {
          if (mounted) {
            setState(() {});
          }
        },
      );

      final loadedRules = await ScheduleService.loadSchedules();
      final screenTime = await ScreenTimeService.fetchDailyScreenTime();
      if (!mounted) return;

      setState(() {
        _rules = loadedRules;
        _screenTimeSnapshot = screenTime;
        _isLoadingSchedules = false;
      });

      await _syncShieldAndStats();
    } catch (e) {
      debugPrint('HomeScreen._initializeDataAndShields note: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedules = false;
        });
      }
    }
  }

  Future<void> _refreshDailyScreenTime() async {
    try {
      final screenTime = await ScreenTimeService.fetchDailyScreenTime();
      if (!mounted) return;
      setState(() {
        _screenTimeSnapshot = screenTime;
      });
    } catch (e) {
      debugPrint('HomeScreen._refreshDailyScreenTime note: $e');
    }
  }

  Future<void> _syncShieldAndStats() async {
    final snapshot = ScheduleService.computeLiveSnapshot(
      rules: _rules,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );

    final sessionRemaining = snapshot.activeRule != null
        ? ScheduleRuleModel.formatDurationMinutes(
            snapshot.activeRule!.currentCycleRemainingMinutes,
          )
        : null;

    final screenTimeToday =
        (_screenTimeSnapshot?.totalMinutes != null &&
            _screenTimeSnapshot!.totalMinutes! > 0)
        ? ScheduleRuleModel.formatDurationMinutes(
            _screenTimeSnapshot!.totalMinutes!,
          )
        : null;

    await ScheduleService.syncNativeShield(
      rules: _rules,
      isOnMindfulBreak: _isOnMindfulBreak,
      sessionRemaining: sessionRemaining,
      protectedToday: snapshot.focusedDuration,
      screenTimeToday: screenTimeToday,
      scheduleTitle: snapshot.title,
    );

    await ScheduleService.syncDailyStats(
      snapshot: snapshot,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-query real usage when returning from Settings / other apps.
    if (state == AppLifecycleState.resumed) {
      _refreshDailyScreenTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        _mindfulBreakTotalSeconds = 0;
        _breakEndTime = null;
      });
      _syncShieldAndStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mindful break ended \u2013 Focus mode and shields resumed.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1D6F58),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MindfulBreakSheet(
        onStartBreakMinutes: (minutes) {
          _mindfulBreakTimer?.cancel();
          final totalSec = minutes * 60;
          final targetEndTime = DateTime.now().add(Duration(seconds: totalSec));

          setState(() {
            _isOnMindfulBreak = true;
            _mindfulBreakTotalSeconds = totalSec;
            _mindfulBreakRemainingSeconds = totalSec;
            _breakEndTime = targetEndTime;
            _mindfulBreakMinutesToday += minutes;
          });
          _syncShieldAndStats();

          _mindfulBreakTimer = Timer.periodic(const Duration(seconds: 1), (
            timer,
          ) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            final now = DateTime.now();
            final remaining = _breakEndTime != null
                ? _breakEndTime!.difference(now).inSeconds
                : _mindfulBreakRemainingSeconds - 1;

            if (remaining <= 0) {
              timer.cancel();
              setState(() {
                _isOnMindfulBreak = false;
                _mindfulBreakRemainingSeconds = 0;
                _mindfulBreakTotalSeconds = 0;
                _breakEndTime = null;
              });
              _syncShieldAndStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mindful break ended \u2013 Focus mode and shields automatically restarted!',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF1D6F58),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } else {
              setState(() {
                _mindfulBreakRemainingSeconds = remaining;
              });
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mindful break started for $minutes minutes'),
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
        snapshot.activeRule ??
        snapshot.nextRule ??
        (_rules.isNotEmpty ? _rules.first : null);

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
          await _refreshDailyScreenTime();
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
          await _refreshDailyScreenTime();
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
                child: CircularProgressIndicator(color: Color(0xFF1D6F58)),
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
            sessionRemaining: snapshot.activeRule != null
                ? ScheduleRuleModel.formatDurationMinutes(
                    snapshot.activeRule!.currentCycleRemainingMinutes)
                : '0m',
            protectedToday: snapshot.focusedDuration,
            screenTimeToday: (_screenTimeSnapshot?.totalMinutes != null &&
                    _screenTimeSnapshot!.totalMinutes! > 0)
                ? ScheduleRuleModel.formatDurationMinutes(
                    _screenTimeSnapshot!.totalMinutes!)
                : '0m',
            focusedDuration: snapshot.focusedDuration,
            focusScore: snapshot.focusScore,
            isOnBreak: _isOnMindfulBreak,
            breakRemainingSeconds: _mindfulBreakRemainingSeconds,
            breakTotalSeconds: _mindfulBreakTotalSeconds,
            onTakeMindfulBreak: _handleTakeMindfulBreak,
            onAdjust: () => _handleAdjustAnchor(snapshot),
          ),

          const SizedBox(height: 20),

          // Feature 2: Daily Screen Time Card (Middle of screen, above Rules & Schedules)
          DailyScreenTimeCard(
            isAuthorized: _screenTimeSnapshot?.isAuthorized ?? false,
            useNativeIosReport:
                _screenTimeSnapshot?.useNativeIosReport ?? false,
            totalMinutes: _screenTimeSnapshot?.totalMinutes,
            apps: _screenTimeSnapshot?.apps ?? const [],
            onConnect: () async {
              await ScreenTimeService.requestAuthorization();
              await _refreshDailyScreenTime();
            },
            onTapHeader: () {
              setState(() {
                _currentTabIndex = 2; // Navigate to Insights tab
              });
            },
          ),

          const SizedBox(height: 26),

          // Feature 3: Rules & Schedules Section (Horizontal Row in Escalator Order)
          RulesSchedulesSection(
            rules: ScheduleService.sortRulesForHomeEscalator(_rules),
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
              '${snapshot.focusedDuration} focused today \u2022 ${snapshot.focusScore} Focus Score',
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
