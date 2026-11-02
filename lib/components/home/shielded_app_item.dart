import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/models/home_models.dart';

class ShieldedAppItem extends StatelessWidget {
  final ShieldedAppModel app;
  final VoidCallback onToggleLock;

  const ShieldedAppItem({
    super.key,
    required this.app,
    required this.onToggleLock,
  });

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleLock,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with bottom-right lock badge
          SizedBox(
            width: 54,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Tinted rounded square
                Positioned(
                  top: 0,
                  left: 0,
                  right: 2,
                  bottom: 4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: app.isLocked ? 1.0 : 0.55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: app.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.04),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _buildAppIcon(),
                    ),
                  ),
                ),

                // Lock badge at bottom-right
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: app.isLocked
                          ? const Color(0xFF332E30)
                          : const Color(0xFF1D6F58),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      app.isLocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 10.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // App Name
          Text(
            app.name,
            style: GoogleFonts.lora(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _primaryText,
            ),
          ),

          const SizedBox(height: 2),

          // Unblock / Block action text
          Text(
            app.isLocked ? 'Unblock' : 'Shield',
            style: GoogleFonts.lora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: app.isLocked ? _mutedText : const Color(0xFF1D6F58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    switch (app.iconType) {
      case ShieldedAppIconType.instagram:
        return Icon(
          Icons.photo_camera_outlined,
          size: 22,
          color: app.iconColor,
        );
      case ShieldedAppIconType.tiktok:
        return Icon(
          Icons.play_circle_outline_rounded,
          size: 22,
          color: app.iconColor,
        );
      case ShieldedAppIconType.x:
        return Text(
          '\uD835\uDD4F', // Mathematical double-struck X matching X logo
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: app.iconColor,
          ),
        );
      case ShieldedAppIconType.youtube:
        return Icon(
          Icons.smart_display_outlined,
          size: 22,
          color: app.iconColor,
        );
      case ShieldedAppIconType.reddit:
        return Icon(
          Icons.forum_outlined,
          size: 20,
          color: app.iconColor,
        );
      case ShieldedAppIconType.snapchat:
        return Icon(
          Icons.notifications_none_rounded,
          size: 22,
          color: app.iconColor,
        );
    }
  }
}

