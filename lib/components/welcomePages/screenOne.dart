import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenOne extends StatefulWidget {
  const ScreenOne({super.key});

  @override
  State<ScreenOne> createState() => _ScreenOneState();
}

class _ScreenOneState extends State<ScreenOne> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            "lib/icons/instagram.png",
                            height: 80,
                            width: 80,
                          ),
                          Image.asset(
                            "lib/icons/tik-tok.png",
                            height: 80,
                            width: 80,
                          ),
                          Image.asset(
                            "lib/icons/youtube.png",
                            height: 80,
                            width: 80,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset(
                            "lib/icons/snapchat.png",
                            height: 80,
                            width: 80,
                          ),
                          Image.asset(
                            "lib/icons/twitter.png",
                            height: 80,
                            width: 80,
                          ),
                          Image.asset(
                            "lib/icons/reddit.png",
                            height: 80,
                            width: 80,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Text(
                "Block out Distractions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff4063e4),
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 10),
              Text(
                "Silence the apps\nthat steal your time.",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Pick Instagram, TikTok or any app that pulls you away. We'll lock them so you don't have to rely on willpower.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 20,
                  fontFamily: GoogleFonts.sora().fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
