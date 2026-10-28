import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/components/welcomePages/welcomePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey =
      dotenv.env['SUPABASE_ANON'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = false;
    try {
      isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      isLoggedIn = false;
    }

    return MaterialApp(
      title: 'Oruv',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const HomeScreen() : const WelcomePage(),
    );
  }
}
