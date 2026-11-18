import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/app_shield_page.dart';
import 'package:oruv/components/onboarding/focus_boundary_page.dart';
import 'package:oruv/components/onboarding/focus_priorities_page.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/time_analysis_page.dart';
import 'package:oruv/components/onboarding/user_profile_page.dart';
import 'package:oruv/components/welcomePages/components/app_shield_status_row.dart';
import 'package:oruv/components/welcomePages/components/hold_to_commit_button.dart';
import 'package:oruv/components/welcomePages/components/time_reclaimed_sheet_body.dart';
import 'package:oruv/components/welcomePages/components/welcome_card_body.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/components/welcomePages/screenOne.dart';
import 'package:oruv/components/welcomePages/screenThree.dart';
import 'package:oruv/components/welcomePages/screenTwo.dart';
import 'package:oruv/services/preferences_service.dart';

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
  final GlobalKey<AppShieldPageState> _appShieldKey =
      GlobalKey<AppShieldPageState>();

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
      case 6:
        return const Color(0xFF101312);
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
    return page == 0 || page == 1 || page == 2 || page == 5 || page == 6;
  }

  void _finishToAuth() async {
    FocusScope.of(context).unfocus();
    _holdController.reset();
    await PreferencesService.setCompletedOnboarding(true);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScreenFour()),
    ).then((_) {
      if (mounted) {
        _holdController.reset();
        setState(() {});
      }
    });
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();

    // Validate Name & Age when on Step 3 (User Profile)
    if (_currentPage == 3) {
      final isValid = _userProfileKey.currentState?.validateAndSave() ?? false;
      if (!isValid) return;
    }

    // Request Screen Time permission first on Step 6 before advancing
    if (_currentPage == 6 && !OnboardingData.instance.screenTimeAuthorized) {
      _appShieldKey.currentState?.requestScreenTimePermission();
      return;
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
    if (_currentPage == 6 && OnboardingData.instance.screenTimeAuthorized) {
      setState(() {
        OnboardingData.instance.screenTimeAuthorized = false;
      });
      return;
    }
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
        return OnboardingData.instance.screenTimeAuthorized
            ? "Continue"
            : "Connect Screen Time";
      default:
        return "Continue";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final darkHeader = _isDarkHeader(_currentPage);
    final headerElementColor = darkHeader
        ? Colors.white
        : const Color(0xFF1E1A1D);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
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

                    SizedBox(
                      width: 90,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _currentPage < 3
                            ? TextButton(
                                onPressed: () async {
                                  await PreferencesService.setCompletedOnboarding(true);
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ScreenFour(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Sign In",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: headerElementColor,
                                  ),
                                ),
                              )
                            : AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _currentPage >= 3 ? 1.0 : 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    "Step ${_currentPage - 2} of 5",
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
                    if (_holdController.value > 0) {
                      _holdController.reset();
                    }
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
                    FocusPrioritiesPage(onChanged: () => setState(() {})),
                    const TimeAnalysisPage(),
                    AppShieldPage(
                      key: _appShieldKey,
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
                          child: _buildSheetContent(
                            _currentPage,
                            isKeyboardOpen,
                          ),
                        ),
                      ),

                      SizedBox(height: isKeyboardOpen ? 4 : 18),

                      // Stationary Primary Button (or Hold to Commit on final step)
                      if (_currentPage == 7)
                        HoldToCommitButton(
                          holdController: _holdController,
                          buttonBgColor: _buttonBgColor,
                        )
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
        return const WelcomeCardBody(
          key: ValueKey('welcome_0'),
          title: "BLOCK DISTRACTIONS",
          subtitle:
              "Lock Instagram, TikTok and any app that\npulls you away \u2014 no willpower needed.",
          metricsChild: TwoColumnMetrics(
            leftVal: "2h+",
            leftLabel: "Saved daily",
            rightVal: "50+",
            rightLabel: "Apps blockable",
          ),
        );
      case 1:
        return const WelcomeCardBody(
          key: ValueKey('welcome_1'),
          title: "SET YOUR SCHEDULE",
          subtitle:
              "Block social media at 10 PM and get it back\nat 8 AM. It runs on its own, every day.",
          metricsChild: TwoColumnMetrics(
            leftVal: "10 PM",
            leftLabel: "Apps lock",
            rightVal: "8 AM",
            rightLabel: "Apps unlock",
          ),
        );
      case 2:
        return const WelcomeCardBody(
          key: ValueKey('welcome_2'),
          title: "FOCUS ANYWHERE",
          subtitle:
              "Create focus modes for work, school or\ncollege and win back hours of attention.",
          metricsChild: CommunityMetric(),
        );
      case 5:
        return const TimeReclaimedSheetBody();
      case 6:
        return const AppShieldStatusRow();
      default:
        return const SizedBox.shrink(key: ValueKey('compact_sheet'));
    }
  }

}
