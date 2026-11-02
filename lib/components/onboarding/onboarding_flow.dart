import 'package:flutter/material.dart';
import 'package:oruv/components/onboarding/app_shield_page.dart';
import 'package:oruv/components/onboarding/focus_boundary_page.dart';
import 'package:oruv/components/onboarding/focus_priorities_page.dart';
import 'package:oruv/components/onboarding/time_analysis_page.dart';
import 'package:oruv/components/onboarding/user_profile_page.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_currentIndex < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishToAuth();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _finishToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ScreenFour()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        children: [
          UserProfilePage(
            onNext: _next,
            onBack: _back,
          ),
          FocusPrioritiesPage(
            onNext: _next,
            onBack: _back,
          ),
          TimeAnalysisPage(
            onNext: _next,
            onBack: _back,
          ),
          AppShieldPage(
            onNext: _next,
            onBack: _back,
          ),
          FocusBoundaryPage(
            onFinish: _finishToAuth,
            onBack: _back,
          ),
        ],
      ),
    );
  }
}

