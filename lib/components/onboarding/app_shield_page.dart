import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class AppShieldPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const AppShieldPage({super.key, required this.onNext, this.onBack});

  @override
  State<AppShieldPage> createState() => _AppShieldPageState();
}

class _AppShieldPageState extends State<AppShieldPage> {
  late Set<String> _selectedCategories;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Social Media & Feeds',
      'installed': '14 apps installed',
      'icon': Icons.groups_outlined,
      'tags': [
        {'name': 'Instagram', 'color': Color(0xFFE1306C)},
        {'name': 'TikTok', 'color': Colors.black},
        {'name': 'X', 'color': Colors.black},
        {'name': 'Threads', 'color': Color(0xFF6E686D)},
        {'name': '+10', 'color': Colors.transparent},
      ],
    },
    {
      'title': 'Endless Video & Streaming',
      'installed': '6 apps installed',
      'icon': Icons.movie_outlined,
      'tags': [
        {'name': 'YouTube', 'color': Color(0xFFFF0000)},
        {'name': 'Netflix', 'color': Color(0xFFE50914)},
        {'name': 'Twitch', 'color': Color(0xFF9146FF)},
        {'name': '+3', 'color': Colors.transparent},
      ],
    },
    {
      'title': 'News & Infinite Browsers',
      'installed': '5 apps installed',
      'icon': Icons.language_outlined,
      'tags': [
        {'name': 'Safari', 'color': Color(0xFF007AFF)},
        {'name': 'Reddit', 'color': Color(0xFFFF4500)},
        {'name': 'Chrome', 'color': Color(0xFF4285F4)},
        {'name': '+2', 'color': Colors.transparent},
      ],
    },
    {
      'title': 'Gaming & Casual Puzzles',
      'installed': '0 apps detected',
      'icon': Icons.sports_esports_outlined,
      'tags': <Map<String, dynamic>>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(OnboardingData.instance.selectedCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    OnboardingData.instance.selectedCategories = _selectedCategories;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                    "Step 4 of 5",
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

            // Main List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "SELECT APPS TO SHIELD FROM YOUR ATTENTION.",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        letterSpacing: 0.3,
                        color: const Color(0xFF1E1A1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll gently lock these during your focus windows. Essentials remain open.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: const Color(0xFF6E686D),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search input
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F8F6),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFEBE5DF)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF8A8287),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Search apps or websites...",
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFB5AFB3),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Categories Cards
                    ...List.generate(_categories.length, (index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategories.contains(
                        cat['title'],
                      );
                      final tags = (cat['tags'] as List<dynamic>?) ?? [];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategories.remove(cat['title']);
                            } else {
                              _selectedCategories.add(cat['title'] as String);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFECE7E2),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F5F2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat['icon'] as IconData,
                                      color: const Color(0xFF1E1A1D),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat['title'] as String,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E1A1D),
                                          ),
                                        ),
                                        Text(
                                          cat['installed'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF8A8287),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF281F24)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF281F24)
                                            : const Color(0xFFD4CEC7),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 15,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: tags.map((t) {
                                    final tMap = t as Map<String, dynamic>;
                                    final tagColor = tMap['color'] as Color;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF7F5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (tagColor !=
                                              Colors.transparent) ...[
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: tagColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            tMap['name'] as String,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF4A4549),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom White Card
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
                  const SizedBox(height: 14),

                  // Status bar row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                          "25 Distractions Shielded",
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
                  ),
                  const SizedBox(height: 16),

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
                        "Set My Focus Rules",
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
