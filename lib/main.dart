import 'package:flutter/material.dart';
//import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/components/welcomePages/screenOne.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oruv',
      debugShowCheckedModeBanner: false,

      //theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: ScreenOne(),
    );
  }
}
