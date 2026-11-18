import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HoldToCommitButton extends StatelessWidget {
  final AnimationController holdController;
  final Color buttonBgColor;

  const HoldToCommitButton({
    super.key,
    required this.holdController,
    this.buttonBgColor = const Color(0xFF281F24),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            if (holdController.status == AnimationStatus.completed) {
              holdController.reset();
            }
            holdController.forward();
          },
          onTapUp: (_) {
            if (holdController.status != AnimationStatus.completed) {
              holdController.reverse();
            }
          },
          onTapCancel: () {
            if (holdController.status != AnimationStatus.completed) {
              holdController.reverse();
            }
          },
          child: AnimatedBuilder(
            animation: holdController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: buttonBgColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    FractionallySizedBox(
                      widthFactor: holdController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF077C6A),
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            holdController.value > 0
                                ? "Holding..."
                                : "Hold to Commit",
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Customize details later in settings",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8A8287),
          ),
        ),
      ],
    );
  }
}
