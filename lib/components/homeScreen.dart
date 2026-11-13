import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oruv/components/home/adjust_anchor_sheet.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/components/home/deep_work_anchor_card.dart';
import 'package:oruv/components/home/home_bottom_nav_bar.dart';
import 'package:oruv/components/home/home_top_app_bar.dart';
import 'package:oruv/components/home/insights_page.dart';
import 'package:oruv/components/home/mindful_break_sheet.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rule_editor_sheet.dart';
import 'package:oruv/components/home/rules_schedules_section.dart';
import 'package:oruv/components/home/shields_page.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/onboarding_service.dart';
import 'package:oruv/components/settings/profile_settings_page.dart';
import 'package:oruv/services/schedule_service.dart';
import 'package:oruv/services/screen_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<AppScreenTimeItem> _topFiveApps = const [];
  String _mostBlockedAppName = '';
  int _mostBlockedAppCount = 0;
  bool _hasMostBlockedNativeToken = false;
  int _lastClockMinute = -1;

  static const String _keyBreakEndTimeMs = 'mindful_break_end_time_ms';
  static const String _keyBreakTotalSec = 'mindful_break_total_seconds';
  static const String _keyBreakMinsToday = 'mindful_break_minutes_today';
  static const String _keyBreakDateStr = 'mindful_break_date_str';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _lastClockMinute = now.hour * 60 + now.minute;
    _initializeDataAndShields();

    // Refresh live progress %, remaining time, and shield enforcement every 15s
    _liveClockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      _checkMindfulBreakExpiry();
      final currentNow = DateTime.now();
      final currentMinute = currentNow.hour * 60 + currentNow.minute;
      if (currentMinute != _lastClockMinute) {
        _lastClockMinute = currentMinute;
        setState(() {});
      }
      _syncShieldAndStats();
      _refreshBlockedAttempts();
      _refreshDailyScreenTime();
    });
  }

  Future<void> _initializeDataAndShields() async {
    try {
      await OnboardingService.loadOnboardingData();
      await _restoreMindfulBreakState();
      await ScheduleService.refreshNativeSelectionCounts(
        onCountUpdated: (_) {
          if (mounted) {
            setState(() {});
          }
        },
      );

      final loadedRules = await ScheduleService.loadSchedules();
      final screenTime = await ScreenTimeService.fetchDailyScreenTime();
      await _refreshBlockedAttempts();
      if (!mounted) return;

      setState(() {
        _rules = loadedRules;
        _screenTimeSnapshot = screenTime;
        _topFiveApps = List.unmodifiable((screenTime.apps).take(5));
        _isLoadingSchedules = false;
      });

      await _syncShieldAndStats();

      // Refresh again shortly after launch once the native extension finishes its report
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _refreshDailyScreenTime();
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _refreshDailyScreenTime();
      });
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
      if (_screenTimeSnapshot?.totalMinutes != screenTime.totalMinutes ||
          _screenTimeSnapshot?.yesterdayMinutes !=
              screenTime.yesterdayMinutes ||
          _screenTimeSnapshot?.timeSavedText != screenTime.timeSavedText ||
          _screenTimeSnapshot?.timeSavedLabel != screenTime.timeSavedLabel ||
          _screenTimeSnapshot?.isSavingTime != screenTime.isSavingTime ||
          _screenTimeSnapshot?.apps.length != screenTime.apps.length) {
        setState(() {
          _screenTimeSnapshot = screenTime;
          _topFiveApps = List.unmodifiable((screenTime.apps).take(5));
        });
        await _syncShieldAndStats();
      }
    } catch (e) {
      debugPrint('HomeScreen._refreshDailyScreenTime note: $e');
    }
  }

  Future<void> _refreshBlockedAttempts() async {
    try {
      final stats = await ScreenTimeService.fetchBlockedAttempts();
      if (!mounted) return;
      final nextName = (stats['appName'] as String?) ?? '';
      final nextCount = (stats['count'] as int?) ?? 0;
      final nextHasToken = stats['hasNativeToken'] == true;
      if (nextName != _mostBlockedAppName ||
          nextCount != _mostBlockedAppCount ||
          nextHasToken != _hasMostBlockedNativeToken) {
        setState(() {
          _mostBlockedAppName = nextName;
          _mostBlockedAppCount = nextCount;
          _hasMostBlockedNativeToken = nextHasToken;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen._refreshBlockedAttempts note: $e');
    }
  }

  Future<void> _syncShieldAndStats() async {
    final snapshot = ScheduleService.computeLiveSnapshot(
      rules: _rules,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
      todayScreenTimeMinutes: _screenTimeSnapshot?.totalMinutes,
      yesterdayScreenTimeMinutes: _screenTimeSnapshot?.yesterdayMinutes,
      timeSavedText: _screenTimeSnapshot?.timeSavedText,
      timeSavedLabel: _screenTimeSnapshot?.timeSavedLabel,
      isSavingTimeOverride: _screenTimeSnapshot?.isSavingTime,
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
      breakEndTime: _breakEndTime,
      breakDurationMinutes: _breakEndTime != null
          ? ((_mindfulBreakTotalSeconds + 59) ~/ 60)
          : null,
      sessionRemaining: sessionRemaining,
      protectedToday: snapshot.shieldDiffFormatted,
      screenTimeToday: screenTimeToday,
      scheduleTitle: snapshot.title,
      projectedTimeText: snapshot.projectedTimeText,
      projectedLabel: snapshot.isSavingTime
          ? 'On Track to Save vs Yesterday'
          : 'Projected Over Yesterday',
      isSavingTime: snapshot.isSavingTime,
    );

    await ScheduleService.syncDailyStats(
      snapshot: snapshot,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMindfulBreakExpiry();
      _syncShieldAndStats();
      _refreshDailyScreenTime();
      _refreshBlockedAttempts();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveClockTimer?.cancel();
    _mindfulBreakTimer?.cancel();
    super.dispose();
  }

  void _checkMindfulBreakExpiry() {
    if (!_isOnMindfulBreak) return;
    final now = DateTime.now();
    if (_breakEndTime != null &&
        (now.isAfter(_breakEndTime!) || now.isAtSameMomentAs(_breakEndTime!))) {
      _mindfulBreakTimer?.cancel();
      _mindfulBreakTimer = null;
      setState(() {
        _isOnMindfulBreak = false;
        _mindfulBreakRemainingSeconds = 0;
        _mindfulBreakTotalSeconds = 0;
        _breakEndTime = null;
      });
      _persistMindfulBreakState();
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
    } else if (_breakEndTime != null) {
      final remaining = _breakEndTime!.difference(now).inSeconds;
      if (remaining != _mindfulBreakRemainingSeconds) {
        setState(() {
          _mindfulBreakRemainingSeconds = remaining.clamp(
            0,
            _mindfulBreakTotalSeconds > 0
                ? _mindfulBreakTotalSeconds
                : remaining,
          );
        });
      }
    }
  }

  void _startMindfulBreakTicker() {
    _mindfulBreakTimer?.cancel();
    _mindfulBreakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkMindfulBreakExpiry();
      if (!_isOnMindfulBreak) {
        timer.cancel();
        _mindfulBreakTimer = null;
      }
    });
  }

  Future<void> _persistMindfulBreakState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isOnMindfulBreak && _breakEndTime != null) {
        await prefs.setInt(
          _keyBreakEndTimeMs,
          _breakEndTime!.millisecondsSinceEpoch,
        );
        await prefs.setInt(_keyBreakTotalSec, _mindfulBreakTotalSeconds);
      } else {
        await prefs.remove(_keyBreakEndTimeMs);
        await prefs.remove(_keyBreakTotalSec);
      }
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_keyBreakDateStr, todayStr);
      await prefs.setInt(_keyBreakMinsToday, _mindfulBreakMinutesToday);
    } catch (_) {}
  }

  Future<void> _restoreMindfulBreakState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final savedDate = prefs.getString(_keyBreakDateStr);
      if (savedDate == todayStr) {
        _mindfulBreakMinutesToday = prefs.getInt(_keyBreakMinsToday) ?? 0;
      } else {
        _mindfulBreakMinutesToday = 0;
        await prefs.setString(_keyBreakDateStr, todayStr);
        await prefs.setInt(_keyBreakMinsToday, 0);
      }

      final endMs = prefs.getInt(_keyBreakEndTimeMs);
      final totalSec = prefs.getInt(_keyBreakTotalSec) ?? 0;
      if (endMs != null && endMs > 0) {
        final targetEnd = DateTime.fromMillisecondsSinceEpoch(endMs);
        final now = DateTime.now();
        if (now.isBefore(targetEnd)) {
          _isOnMindfulBreak = true;
          _breakEndTime = targetEnd;
          _mindfulBreakTotalSeconds = totalSec;
          _mindfulBreakRemainingSeconds = targetEnd.difference(now).inSeconds;
          _startMindfulBreakTicker();
        } else {
          await prefs.remove(_keyBreakEndTimeMs);
          await prefs.remove(_keyBreakTotalSec);
        }
      }
    } catch (_) {}
  }

  void _handleTakeMindfulBreak() {
    if (_isOnMindfulBreak) {
      _mindfulBreakTimer?.cancel();
      _mindfulBreakTimer = null;
      setState(() {
        _isOnMindfulBreak = false;
        _mindfulBreakRemainingSeconds = 0;
        _mindfulBreakTotalSeconds = 0;
        _breakEndTime = null;
      });
      _persistMindfulBreakState();
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
          _persistMindfulBreakState();
          _syncShieldAndStats();
          _startMindfulBreakTicker();

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
        existingRules: _rules,
        targetRuleId: targetRule?.id,
        activeDays: targetRule?.activeDays ?? const {'M', 'T', 'W', 'T2', 'F'},
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
    if (isActive) {
      final rule = _rules.firstWhere((r) => r.id == ruleId);
      final otherActiveRules = _rules
          .where((r) => r.isActive && r.id != ruleId)
          .toList();
      final conflict = ScheduleRuleModel.findConflictingSchedule(
        startTime: rule.startTime,
        endTime: rule.endTime,
        activeDays: rule.activeDays,
        existingRules: otherActiveRules,
      );
      if (conflict != null) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot activate "${rule.title}": overlaps with active schedule "${conflict.title}" (${conflict.timeRange}).',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

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
        existingRules: _rules,
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
        existingRules: _rules,
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

  void _selectTab(int index) {
    if (_currentTabIndex != index) {
      setState(() {
        _currentTabIndex = index;
      });
      _refreshDailyScreenTime();
      _refreshBlockedAttempts();
    }
  }

  void _handleViewAllRules() {
    _selectTab(1);
  }

  void _handleSelectInsightsTab() {
    _selectTab(2);
  }

  Future<void> _handleConnectScreenTime() async {
    await ScreenTimeService.requestAuthorization();
    await _refreshDailyScreenTime();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ScheduleService.computeLiveSnapshot(
      rules: _rules,
      mindfulBreakMinutesToday: _mindfulBreakMinutesToday,
      todayScreenTimeMinutes: _screenTimeSnapshot?.totalMinutes,
      yesterdayScreenTimeMinutes: _screenTimeSnapshot?.yesterdayMinutes,
      timeSavedText: _screenTimeSnapshot?.timeSavedText,
      timeSavedLabel: _screenTimeSnapshot?.timeSavedLabel,
      isSavingTimeOverride: _screenTimeSnapshot?.isSavingTime,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeTopAppBar(
        onProfileTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSettingsPage(),
            ),
          );
          if (mounted) {
            setState(() {});
            _refreshDailyScreenTime();
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoadingSchedules
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D6F58)),
              )
            : _buildTabContent(snapshot),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentTabIndex,
        onTabSelected: _selectTab,
      ),
    );
  }

  Widget _buildTabContent(LiveAnchorSnapshot snapshot) {
    return IndexedStack(
      index: _currentTabIndex,
      children: [
        _buildHomeDashboard(snapshot),
        ShieldsPage(
          rules: _rules,
          onRuleToggled: _handleRuleToggled,
          onEditRule: _openEditRuleSheet,
          onAddRule: _openAddRuleSheet,
        ),
        InsightsPage(
          screenTimeSnapshot: _screenTimeSnapshot,
          timeSavedText: snapshot.projectedTimeText,
          onConnectScreenTime: _handleConnectScreenTime,
        ),
      ],
    );
  }

  Widget _buildHomeDashboard(LiveAnchorSnapshot snapshot) {
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
              isAuthorized: _screenTimeSnapshot?.isAuthorized ?? false,
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
              mostBlockedAppName: _mostBlockedAppName,
              mostBlockedAppCount: _mostBlockedAppCount,
              hasMostBlockedNativeToken: _hasMostBlockedNativeToken,
              screenTimeToday:
                  (_screenTimeSnapshot?.totalMinutes != null &&
                      _screenTimeSnapshot!.totalMinutes! > 0)
                  ? ScheduleRuleModel.formatDurationMinutes(
                      _screenTimeSnapshot!.totalMinutes!,
                    )
                  : '0m',
              focusedDuration: snapshot.focusedDuration,
              focusScore: snapshot.focusScore,
              isOnBreak: _isOnMindfulBreak,
              breakRemainingSeconds: _mindfulBreakRemainingSeconds,
              breakTotalSeconds: _mindfulBreakTotalSeconds,
              onTakeMindfulBreak: _handleTakeMindfulBreak,
              onAdjust: () => _handleAdjustAnchor(snapshot),
            ),
          ),

          const SizedBox(height: 20),

          // Feature 2: Daily Screen Time Card (Middle of screen, above Rules & Schedules)
          DailyScreenTimeCard(
            isAuthorized: _screenTimeSnapshot?.isAuthorized ?? false,
            useNativeIosReport:
                _screenTimeSnapshot?.useNativeIosReport ?? false,
            totalMinutes: _screenTimeSnapshot?.totalMinutes,
            apps: _topFiveApps,
            onConnect: _handleConnectScreenTime,
            onTap: _handleSelectInsightsTab,
            onTapHeader: _handleSelectInsightsTab,
          ),

          const SizedBox(height: 26),

          // Feature 3: Rules & Schedules Section (Horizontal Row in Escalator Order)
          RepaintBoundary(
            child: RulesSchedulesSection(
              rules: ScheduleService.sortRulesForHomeEscalator(_rules),
              onRuleToggled: _handleRuleToggled,
              onRuleTap: _openEditRuleSheet,
              onViewAll: _handleViewAllRules,
              isGrid: false,
            ),
          ),
        ],
      ),
    );
  }
}
