import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/home/shielded_app_item.dart';

class ShieldedNowCard extends StatelessWidget {
  final List<ShieldedAppModel> apps;
  final String unlockTime;
  final bool isPauseActive;
  final int pauseRemainingSeconds;
  final void Function(String appId) onToggleAppLock;
  final VoidCallback onUnblockAll;
  final VoidCallback onShieldMoreApps;
  final VoidCallback onRequest5mPause;

  const ShieldedNowCard({
    super.key,
    required this.apps,
    this.unlockTime = '5:00 PM',
    this.isPauseActive = false,
    this.pauseRemainingSeconds = 0,
    required this.onToggleAppLock,
    required this.onUnblockAll,
    required this.onShieldMoreApps,
    required this.onRequest5mPause,
  });

  static const Color _accentGreen = Color(0xFF1D6F58);
  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _cardBorder = Color(0xFFECE8E4);

  String _formatPauseCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:${s}s left';
  }

  @override
  Widget build(BuildContext context) {
    final allUnlocked = apps.every((a) => !a.isLocked);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Subtitle on left, "Unblock All" on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shielded Now',
                      style: GoogleFonts.lora(
                        fontSize: 19.5,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPauseActive
                          ? 'Paused for 5m (${_formatPauseCountdown(pauseRemainingSeconds)})'
                          : 'Locked until $unlockTime or manual break',
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onUnblockAll,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    allUnlocked ? 'Lock All' : 'Unblock All',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Row of 5 Shielded Apps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: apps.map((app) {
              return ShieldedAppItem(
                app: app,
                onToggleLock: () => onToggleAppLock(app.id),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFF2EEEA),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 14),

          // Footer Actions: "+ Shield More Apps" and "Request 5m Pause"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onShieldMoreApps,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: _primaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shield More Apps',
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: onRequest5mPause,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPauseActive
                          ? Icons.timer_outlined
                          : Icons.hourglass_empty_rounded,
                      size: 16,
                      color: _accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPauseActive
                          ? 'Resume Shield'
                          : 'Request 5m Pause',
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

