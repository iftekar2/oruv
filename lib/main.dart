import 'package:flutter/material.dart';
import 'package:oruv/components/welcomePages/welcomePage.dart';

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
      home: WelcomePage(),
    );
  }
}
