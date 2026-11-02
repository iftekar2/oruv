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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  late String _scheduleStart;
  late String _scheduleEnd;
  late bool _strictLock;

  bool _isOnMindfulBreak = false;

  late List<ScheduleRuleModel> _rules;

  @override
  void initState() {
    super.initState();
    _scheduleStart = OnboardingData.instance.scheduleStart.isNotEmpty
        ? OnboardingData.instance.scheduleStart
        : '9:00 AM';
    _scheduleEnd = OnboardingData.instance.scheduleEnd.isNotEmpty
        ? OnboardingData.instance.scheduleEnd
        : '5:00 PM';
    _strictLock = OnboardingData.instance.strictLock;

    _rules = [
      ScheduleRuleModel(
        id: 'work_time',
        title: 'Work Time',
        startTime: _scheduleStart,
        endTime: _scheduleEnd,
        enforcementMode: _strictLock
            ? 'Strict enforcement mode'
            : 'Balanced enforcement mode',
        isActive: true,
        selectedAppIds: const {'instagram', 'x', 'youtube'},
        extraBlockedCount: 22,
      ),
      const ScheduleRuleModel(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        startTime: '9:30 PM',
        endTime: '7:00 AM',
        enforcementMode: 'Strict enforcement mode',
        isActive: true,
        selectedAppIds: {'tiktok', 'instagram'},
        extraBlockedCount: 14,
      ),
      const ScheduleRuleModel(
        id: 'morning_clarity',
        title: 'Morning Clarity',
        startTime: '6:30 AM',
        endTime: '8:30 AM',
        enforcementMode: 'Gentle reminder mode',
        isActive: true,
        selectedAppIds: {'x', 'reddit'},
        extraBlockedCount: 8,
      ),
    ];
  }

  void _handleTakeMindfulBreak() {
    if (_isOnMindfulBreak) {
      setState(() {
        _isOnMindfulBreak = false;
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MindfulBreakSheet(
        onStartBreakMinutes: (minutes) {
          setState(() {
            _isOnMindfulBreak = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mindful break started for $minutes minutes.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1D6F58),
            ),
          );
        },
      ),
    );
  }

  void _handleAdjustAnchor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AdjustAnchorSheet(
        initialStartTime: _scheduleStart,
        initialEndTime: _scheduleEnd,
        initialStrictLock: _strictLock,
        onSave: (start, end, strict) {
          setState(() {
            _scheduleStart = start;
            _scheduleEnd = end;
            _strictLock = strict;
            OnboardingData.instance.scheduleStart = start;
            OnboardingData.instance.scheduleEnd = end;
            OnboardingData.instance.strictLock = strict;

            final idx = _rules.indexWhere((r) => r.id == 'work_time');
            if (idx != -1) {
              _rules[idx] = _rules[idx].copyWith(
                startTime: start,
                endTime: end,
                enforcementMode: strict
                    ? 'Strict enforcement mode'
                    : 'Balanced enforcement mode',
              );
            }
          });
        },
      ),
    );
  }

  void _handleRuleToggled(String ruleId, bool isActive) {
    setState(() {
      _rules = _rules.map((r) {
        if (r.id == ruleId) {
          return r.copyWith(isActive: isActive);
        }
        return r;
      }).toList();
    });
  }

  void _openAddRuleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RuleEditorSheet(
        onSave: (newRule) {
          setState(() {
            _rules = [newRule, ..._rules];
          });
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
        onSave: (updatedRule) {
          setState(() {
            _rules = _rules.map((r) {
              if (r.id == updatedRule.id) {
                return updatedRule;
              }
              return r;
            }).toList();

            if (updatedRule.id == 'work_time') {
              _scheduleStart = updatedRule.startTime;
              _scheduleEnd = updatedRule.endTime;
              OnboardingData.instance.scheduleStart = updatedRule.startTime;
              OnboardingData.instance.scheduleEnd = updatedRule.endTime;
            }
          });
        },
        onDelete: () {
          setState(() {
            _rules = _rules.where((r) => r.id != rule.id).toList();
          });
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HomeTopAppBar(),
      body: SafeArea(bottom: false, child: _buildActiveTabBody()),
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

  Widget _buildActiveTabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeDashboard();
      case 1:
        return ShieldsPage(
          rules: _rules,
          onRuleToggled: _handleRuleToggled,
          onEditRule: _openEditRuleSheet,
          onAddRule: _openAddRuleSheet,
        );
      case 2:
        return _buildInsightsTabPlaceholder();
      default:
        return _buildHomeDashboard();
    }
  }

  Widget _buildHomeDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature 1: Deep Work Anchor Card
          DeepWorkAnchorCard(
            scheduleStart: _scheduleStart,
            scheduleEnd: _scheduleEnd,
            isOnBreak: _isOnMindfulBreak,
            onTakeMindfulBreak: _handleTakeMindfulBreak,
            onAdjust: _handleAdjustAnchor,
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

  Widget _buildInsightsTabPlaceholder() {
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
              '1h 45m focused today \u2022 88 Focus Score',
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
