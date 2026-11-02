import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class FocusPrioritiesPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const FocusPrioritiesPage({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<FocusPrioritiesPage> createState() => _FocusPrioritiesPageState();
}

class _FocusPrioritiesPageState extends State<FocusPrioritiesPage> {
  late String _selectedPriority;
  late String _selectedScreenTime;

  final List<Map<String, dynamic>> _priorities = [
    {
      'title': 'Deep Work & Career Focus',
      'subtitle': 'Protect unbroken hours for high-value building and thinking',
      'icon': Icons.work_outline_rounded,
    },
    {
      'title': 'Reclaim Evening & Sleep Peace',
      'subtitle': 'Stop late-night doomscrolling and digital blue light',
      'icon': Icons.nightlight_outlined,
    },
    {
      'title': 'Presence with Family & Friends',
      'subtitle': 'Be actually there when with loved ones',
      'icon': Icons.favorite_border_rounded,
    },
    {
      'title': 'Mental Clarity & Calm',
      'subtitle': 'Reduce constant notification anxiety and fragmented focus',
      'icon': Icons.spa_outlined,
    },
  ];

  final List<String> _screenTimes = [
    '< 2 hours',
    '3 - 4 hours',
    '5 - 6 hours',
    '7+ hours',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPriority = OnboardingData.instance.focusPriority;
    _selectedScreenTime = OnboardingData.instance.dailyScreenTime;
  }

  void _submit() {
    OnboardingData.instance.focusPriority = _selectedPriority;
    OnboardingData.instance.dailyScreenTime = _selectedScreenTime;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: widget.onBack,
                      color: const Color(0xFF1E1A1D),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    "Step 2 of 5",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8A8287),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "What matters most to your focus right now?",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: const Color(0xFF1E1A1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select what you want to protect from digital drift.",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: const Color(0xFF6E686D),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Priority options
                    ...List.generate(_priorities.length, (index) {
                      final item = _priorities[index];
                      final isSelected = _selectedPriority == item['title'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPriority = item['title'];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF077C6A)
                                  : const Color(0xFFECE7E2),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF077C6A).withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: const Color(0xFF1E1A1D),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E1A1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: const Color(0xFF6E686D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF077C6A)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF077C6A)
                                        : const Color(0xFFD4CEC7),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFECE7E2), thickness: 1),
                    const SizedBox(height: 18),

                    // Daily screen time section
                    Text(
                      "What is your estimated daily screen time?",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1A1D),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _screenTimes.map((time) {
                          final isSelected = _selectedScreenTime == time;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedScreenTime = time;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1E1A1D)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1E1A1D)
                                        : const Color(0xFFECE7E2),
                                  ),
                                ),
                                child: Text(
                                  time,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF6E686D),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Continue Sheet
            Container(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFCF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DCD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF281F24),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF281F24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDED7CE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

