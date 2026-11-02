import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';

class AppShieldPage extends StatefulWidget {
  final VoidCallback? onChanged;

  const AppShieldPage({
    super.key,
    this.onChanged,
  });

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
        {'name': 'Instagram', 'color': const Color(0xFFE1306C)},
        {'name': 'TikTok', 'color': Colors.black},
        {'name': 'X', 'color': Colors.black},
        {'name': 'Threads', 'color': const Color(0xFF6E686D)},
        {'name': '+10', 'color': Colors.transparent},
      ],
    },
    {
      'title': 'Endless Video & Streaming',
      'installed': '6 apps installed',
      'icon': Icons.movie_outlined,
      'tags': [
        {'name': 'YouTube', 'color': const Color(0xFFFF0000)},
        {'name': 'Netflix', 'color': const Color(0xFFE50914)},
        {'name': 'Twitch', 'color': const Color(0xFF9146FF)},
        {'name': '+3', 'color': Colors.transparent},
      ],
    },
    {
      'title': 'News & Infinite Browsers',
      'installed': '5 apps installed',
      'icon': Icons.language_outlined,
      'tags': [
        {'name': 'Safari', 'color': const Color(0xFF007AFF)},
        {'name': 'Reddit', 'color': const Color(0xFFFF4500)},
        {'name': 'Chrome', 'color': const Color(0xFF4285F4)},
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFECE7E2)),
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
                      keyboardAppearance: Brightness.light,
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
              final isSelected = _selectedCategories.contains(cat['title']);
              final tags = (cat['tags'] as List<dynamic>?) ?? [];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(cat['title']);
                    } else {
                      _selectedCategories.add(cat['title'] as String);
                    }
                    OnboardingData.instance.selectedCategories =
                        Set.from(_selectedCategories);
                  });
                  widget.onChanged?.call();
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
                        color: Colors.black.withValues(alpha: 0.02),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  if (tagColor != Colors.transparent) ...[
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

            // Always Allowed Essentials Card
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFECE7E2),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF077C6A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Always Allowed Essentials",
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1A1D),
                          ),
                        ),
                      ),
                      Text(
                        "PROTECTED",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF077C6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "These will never be locked, keeping you reachable and functional for emergencies.",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.35,
                      color: const Color(0xFF6E686D),
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
