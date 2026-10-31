import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oruv/components/auth/resetPassword.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/components/welcomePages/welcomePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = false;
    try {
      isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      isLoggedIn = false;
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Oruv',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const HomeScreen() : const WelcomePage(),
    );
  }
}
