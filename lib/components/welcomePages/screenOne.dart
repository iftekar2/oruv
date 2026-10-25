import 'package:flutter/material.dart';

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

      appBar: AppBar(backgroundColor: Colors.white),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),

        child: Column(
          children: [
            Image.asset("lib/icons/instagram.png", height: 80, width: 80),
            Image.asset("lib/icons/tik-tok.png", height: 80, width: 80),
            Image.asset("lib/icons/youtube.png", height: 80, width: 80),
            Image.asset("lib/icons/snapchat.png", height: 80, width: 80),
            Image.asset("lib/icons/twitter.png", height: 80, width: 80),
            Image.asset("lib/icons/reddit.png", height: 80, width: 80),
          ],
        ),
      ),
    );
  }
}
