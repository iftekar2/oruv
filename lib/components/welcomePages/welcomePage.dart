import 'package:flutter/material.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/components/welcomePages/screenOne.dart';
import 'package:oruv/components/welcomePages/screenThree.dart';
import 'package:oruv/components/welcomePages/screenTwo.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScreenFour()),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const ClampingScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          ScreenOne(
            onNext: _nextPage,
            onSkip: _navigateToAuth,
          ),
          ScreenTwo(
            onNext: _nextPage,
            onSkip: _navigateToAuth,
          ),
          ScreenThree(
            onGetStarted: _navigateToAuth,
            onSkip: _navigateToAuth,
          ),
        ],
      ),
    );
  }
}
