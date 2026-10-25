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
  int _totalTabs = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },

        children: [ScreenOne(), ScreenTwo(), ScreenThree(), ScreenFour()],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  _totalTabs,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  _currentPage > 0
                      ? TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },

                          child: Text(
                            "Previous",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        )
                      : const SizedBox(width: 80),

                  TextButton(
                    onPressed: () {
                      if (_currentPage < _totalTabs - 1) {
                        // Slide to the next page
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // User is on the last page, navigate to Home/Login
                        // Navigator.pushReplacementNamed(context, '/login');
                      }
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff4063e4),
                        borderRadius: BorderRadius.circular(30),
                      ),

                      height: 50,
                      width: 100,

                      child: Center(
                        child: Text(
                          _currentPage == _totalTabs - 1 ? "Finish" : "Next",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
