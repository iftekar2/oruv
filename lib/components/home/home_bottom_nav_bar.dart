import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const Color _activeColor = Color(0xFF1B1B1D);
  static const Color _inactiveIconColor = Color(0xFF423E41);
  static const Color _inactiveTextColor = Color(0xFF6E6A6E);

  @override
  Widget build(BuildContext context) {
    final items = <_NavBarItemData>[
      const _NavBarItemData(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),

      const _NavBarItemData(
        label: 'Shields',
        icon: Icons.shield_outlined,
        activeIcon: Icons.shield_rounded,
      ),

      const _NavBarItemData(
        label: 'Insights',
        icon: Icons.bar_chart_rounded,
        activeIcon: Icons.bar_chart_rounded,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFEEEAE6), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 30,
                        color: isSelected ? _activeColor : _inactiveIconColor,
                      ),

                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? _activeColor : _inactiveTextColor,
                        ),
                      ),

                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 22 : 0,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2B2628)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavBarItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
