import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/adjust_anchor_sheet.dart';
import 'package:oruv/components/home/deep_work_anchor_card.dart';
import 'package:oruv/components/home/home_bottom_nav_bar.dart';
import 'package:oruv/components/home/home_top_app_bar.dart';
import 'package:oruv/components/home/mindful_break_sheet.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/rules_schedules_section.dart';
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
        timeRange: '$_scheduleStart \u2013 $_scheduleEnd',
        enforcementMode: _strictLock
            ? 'Strict enforcement mode'
            : 'Balanced enforcement mode',
        isActive: true,
        badges: const [
          AppBadgeInfo(label: 'IG', backgroundColor: Color(0xFFFADCE4)),
          AppBadgeInfo(label: 'X', backgroundColor: Color(0xFFECEEEF)),
          AppBadgeInfo(label: 'YT', backgroundColor: Color(0xFFFDE8B2)),
          AppBadgeInfo(label: '+22', backgroundColor: Color(0xFFEDE8E5)),
        ],
        blockedCount: 25,
      ),
      const ScheduleRuleModel(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        timeRange: '9:30 PM \u2013 7:00 AM',
        enforcementMode: 'Strict enforcement mode',
        isActive: true,
        badges: [
          AppBadgeInfo(label: 'TT', backgroundColor: Color(0xFFEBE7E5)),
          AppBadgeInfo(label: 'IG', backgroundColor: Color(0xFFFADCE4)),
          AppBadgeInfo(label: '+14', backgroundColor: Color(0xFFEDE8E5)),
        ],
        blockedCount: 16,
      ),
      const ScheduleRuleModel(
        id: 'morning_clarity',
        title: 'Morning Clarity',
        timeRange: '6:30 AM \u2013 8:30 AM',
        enforcementMode: 'Gentle reminder mode',
        isActive: true,
        badges: [
          AppBadgeInfo(label: 'X', backgroundColor: Color(0xFFECEEEF)),
          AppBadgeInfo(label: 'RD', backgroundColor: Color(0xFFFDF0E5)),
          AppBadgeInfo(label: '+8', backgroundColor: Color(0xFFEDE8E5)),
        ],
        blockedCount: 10,
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

            if (_rules.isNotEmpty) {
              _rules[0] = _rules[0].copyWith(
                timeRange: '$start \u2013 $end',
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
        return _buildShieldsTabPlaceholder();
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

          // Feature 2: Rules & Schedules Section
          RulesSchedulesSection(
            rules: _rules,
            onRuleToggled: _handleRuleToggled,
            onViewAll: _handleViewAllRules,
          ),
        ],
      ),
    );
  }

  Widget _buildShieldsTabPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shields & Schedules',
            style: GoogleFonts.lora(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your active rules and blocked applications',
            style: GoogleFonts.lora(
              fontSize: 13.5,
              color: const Color(0xFF6E6A6E),
            ),
          ),
          const SizedBox(height: 22),
          RulesSchedulesSection(
            rules: _rules,
            onRuleToggled: _handleRuleToggled,
            onViewAll: () {},
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
