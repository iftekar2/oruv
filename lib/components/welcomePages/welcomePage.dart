import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/app_shield_page.dart';
import 'package:oruv/components/onboarding/focus_boundary_page.dart';
import 'package:oruv/components/onboarding/focus_priorities_page.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/time_analysis_page.dart';
import 'package:oruv/components/onboarding/user_profile_page.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/components/welcomePages/screenOne.dart';
import 'package:oruv/components/welcomePages/screenThree.dart';
import 'package:oruv/components/welcomePages/screenTwo.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 8;
  static const Color _cardBgColor = Color(0xFFFDFCF8);
  static const Color _buttonBgColor = Color(0xFF281F24);

  final PageController _pageController = PageController();
  final GlobalKey<UserProfilePageState> _userProfileKey =
      GlobalKey<UserProfilePageState>();

  int _currentPage = 0;
  late AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishToAuth();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(int page) {
    switch (page) {
      case 0:
        return const Color(0xFF8C6D73);
      case 1:
        return const Color(0xFF077C6A);
      case 2:
        return const Color(0xFFF1BE41);
      case 5:
        return const Color(0xFF161616);
      default:
        return const Color(0xFFFAF8F5);
    }
  }

  Color _getHandleColor(int page) {
    switch (page) {
      case 0:
        return const Color(0xFF8C6D73);
      case 1:
        return const Color(0xFF077C6A);
      case 2:
        return const Color(0xFFF1BE41);
      default:
        return const Color(0xFFE0DCD6);
    }
  }

  bool _isDarkHeader(int page) {
    return page == 0 || page == 1 || page == 2 || page == 5;
  }

  void _finishToAuth() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScreenFour()),
    );
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();

    // Validate Name & Age when on Step 3 (User Profile)
    if (_currentPage == 3) {
      final isValid = _userProfileKey.currentState?.validateAndSave() ?? false;
      if (!isValid) return;
    }

    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishToAuth();
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _getButtonLabel(int page) {
    switch (page) {
      case 5:
        return "I Want My Time Back";
      case 6:
        return "Set My Focus Rules";
      default:
        return "Continue";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final darkHeader = _isDarkHeader(_currentPage);
    final headerElementColor =
        darkHeader ? Colors.white : const Color(0xFF1E1A1D);

    return Scaffold(
      backgroundColor: _cardBgColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        color: _getBackgroundColor(_currentPage),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Stationary Top Header Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _currentPage > 0 ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: _currentPage == 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: headerElementColor,
                              ),
                              onPressed: _prevPage,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.outfit(
                        color: headerElementColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      child: const Text("f."),
                    ),
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _currentPage >= 3 ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _currentPage >= 3
                                  ? "Step ${_currentPage - 2} of 5"
                                  : "",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: darkHeader
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : const Color(0xFF8A8287),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Moving Background Content Area
              Expanded(
                child: PageView(
                  physics: _currentPage < 3
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (index) {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    const ScreenOne(),
                    const ScreenTwo(),
                    const ScreenThree(),
                    UserProfilePage(
                      key: _userProfileKey,
                      onSubmitted: _nextPage,
                    ),
                    FocusPrioritiesPage(
                      onChanged: () => setState(() {}),
                    ),
                    const TimeAnalysisPage(),
                    AppShieldPage(
                      onChanged: () => setState(() {}),
                    ),
                    const FocusBoundaryPage(),
                  ],
                ),
              ),

              // Stationary Bottom Sheet
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _cardBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  28,
                  isKeyboardOpen ? 10 : 16,
                  28,
                  isKeyboardOpen ? 10 : 20,
                ),
                child: SafeArea(
                  top: false,
                  bottom: !isKeyboardOpen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pull / accent handle bar
                      if (!isKeyboardOpen)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getHandleColor(_currentPage),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                      // Smoothly resizing upper sheet body
                      AnimatedSize(
                        duration: const Duration(milliseconds: 340),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _buildSheetContent(_currentPage, isKeyboardOpen),
                        ),
                      ),

                      SizedBox(height: isKeyboardOpen ? 4 : 18),

                      // Stationary Primary Button (or Hold to Commit on final step)
                      if (_currentPage == 7)
                        _buildHoldToCommitButton()
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonBgColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _getButtonLabel(_currentPage),
                                key: ValueKey<String>(
                                  _getButtonLabel(_currentPage),
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Stationary Progress Dots
                      if (!isKeyboardOpen) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalSteps, (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF281F24)
                                    : const Color(0xFFDED7CE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetContent(int page, bool isKeyboardOpen) {
    if (isKeyboardOpen && page >= 3) {
      return const SizedBox.shrink(key: ValueKey('keyboard_compact'));
    }

    switch (page) {
      case 0:
        return _buildWelcomeCardBody(
          key: const ValueKey('welcome_0'),
          title: "BLOCK DISTRACTIONS",
          subtitle:
              "Lock Instagram, TikTok and any app that\npulls you away \u2014 no willpower needed.",
          metricsChild: _buildTwoColumnMetrics(
            leftVal: "2h+",
            leftLabel: "Saved daily",
            rightVal: "50+",
            rightLabel: "Apps blockable",
          ),
        );
      case 1:
        return _buildWelcomeCardBody(
          key: const ValueKey('welcome_1'),
          title: "SET YOUR SCHEDULE",
          subtitle:
              "Block social media at 10 PM and get it back\nat 8 AM. It runs on its own, every day.",
          metricsChild: _buildTwoColumnMetrics(
            leftVal: "10 PM",
            leftLabel: "Apps lock",
            rightVal: "8 AM",
            rightLabel: "Apps unlock",
          ),
        );
      case 2:
        return _buildWelcomeCardBody(
          key: const ValueKey('welcome_2'),
          title: "FOCUS ANYWHERE",
          subtitle:
              "Create focus modes for work, school or\ncollege and win back hours of attention.",
          metricsChild: _buildCommunityMetric(),
        );
      case 5:
        return _buildTimeReclaimedSheetBody();
      case 6:
        return _buildAppShieldStatusRow();
      default:
        return const SizedBox.shrink(key: ValueKey('compact_sheet'));
    }
  }

  Widget _buildWelcomeCardBody({
    required Key key,
    required String title,
    required String subtitle,
    required Widget metricsChild,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 22),
        SizedBox(
          height: 38,
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: const Color(0xFF1E1A1D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: Center(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A8287),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: Center(child: metricsChild),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTwoColumnMetrics({
    required String leftVal,
    required String leftLabel,
    required String rightVal,
    required String rightLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leftVal,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1A1D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leftLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A8287),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: const Color(0xFFE5DFD9),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rightVal,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1A1D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rightLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A8287),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityMetric() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          height: 28,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C6D73),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _cardBgColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF077C6A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _cardBgColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 36,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1BE41),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _cardBgColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "12K+",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1A1D),
              ),
            ),
            Text(
              "Focused people",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A8287),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeReclaimedSheetBody() {
    final screenTime = OnboardingData.instance.dailyScreenTime;
    String reclaimedDaily = "2h 30m";
    int daysGivenBack = 38;

    if (screenTime == '< 2 hours') {
      reclaimedDaily = "1h 15m";
      daysGivenBack = 19;
    } else if (screenTime == '5 - 6 hours') {
      reclaimedDaily = "3h 45m";
      daysGivenBack = 57;
    } else if (screenTime == '7+ hours') {
      reclaimedDaily = "5h 00m";
      daysGivenBack = 76;
    }

    return Column(
      key: const ValueKey('time_reclaimed_sheet'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 18),
        Text(
          "TIME RECLAIMED",
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: const Color(0xFF1E1A1D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Honest projections when friction is placed between\nimpulse and action.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.4,
            color: const Color(0xFF8A8287),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE5DF)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          reclaimedDaily,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1A1D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Reclaimed daily",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8A8287),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: const Color(0xFFE5DFD9),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "$daysGivenBack Days",
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1A1D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Given back / yr",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8A8287),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFEBE5DF), thickness: 0.8),
              const SizedBox(height: 8),
              Text(
                "94%",
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF077C6A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Report less fog",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A8287),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAppShieldStatusRow() {
    final cats = OnboardingData.instance.selectedCategories;
    int appCount = 0;
    if (cats.contains('Social Media & Feeds')) appCount += 14;
    if (cats.contains('Endless Video & Streaming')) appCount += 6;
    if (cats.contains('News & Infinite Browsers')) appCount += 5;
    if (cats.contains('Gaming & Casual Puzzles')) appCount += 3;

    return Padding(
      key: const ValueKey('app_shield_status'),
      padding: const EdgeInsets.only(top: 14.0, left: 4.0, right: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF077C6A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$appCount Distractions Shielded",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1A1D),
            ),
          ),
          const Spacer(),
          Text(
            "~3.5h saved daily",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8A8287),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldToCommitButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _holdController.forward(),
          onTapUp: (_) {
            if (_holdController.status != AnimationStatus.completed) {
              _holdController.reverse();
            }
          },
          onTapCancel: () {
            if (_holdController.status != AnimationStatus.completed) {
              _holdController.reverse();
            }
          },
          child: AnimatedBuilder(
            animation: _holdController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _buttonBgColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    FractionallySizedBox(
                      widthFactor: _holdController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF077C6A),
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _holdController.value > 0
                                ? "Holding..."
                                : "Hold to Commit",
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Customize details later in settings",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8A8287),
          ),
        ),
      ],
    );
  }
}
