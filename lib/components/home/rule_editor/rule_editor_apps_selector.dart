import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RuleEditorAppsSelector extends StatelessWidget {
  final int extraBlockedCount;
  final bool isPickerOpen;
  final VoidCallback onTap;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFEBE6E1);
  static const Color _accentGreen = Color(0xFF1D6F58);

  const RuleEditorAppsSelector({
    super.key,
    required this.extraBlockedCount,
    required this.isPickerOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SHIELDED APPS',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _mutedText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFEA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        size: 22,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose from All iPhone Apps & Categories',
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: _primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            extraBlockedCount > 0
                                ? 'Tap to add or remove blocked apps'
                                : 'Tap to select apps & websites to block',
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: _mutedText,
                    ),
                  ],
                ),
                if (extraBlockedCount > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(
                    color: Color(0xFFF2EEEA),
                    height: 1,
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 28,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$extraBlockedCount ${extraBlockedCount == 1 ? 'App' : 'Apps'} chosen to block',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: _primaryText,
                            ),
                          ),
                        ),
                        if (Platform.isIOS && !isPickerOpen)
                          ClipRect(
                            child: SizedBox(
                              width: 110,
                              height: 28,
                              child: IgnorePointer(
                                child: UiKitView(
                                  key: ValueKey<int>(extraBlockedCount),
                                  viewType: 'oruv/selected_apps_icons',
                                  creationParamsCodec:
                                      const StandardMessageCodec(),
                                ),
                              ),
                            ),
                          )
                        else if (Platform.isIOS)
                          const SizedBox(width: 110, height: 28),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
