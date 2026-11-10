import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oruv/components/auth/resetPassword.dart';
import 'package:oruv/components/homeScreen.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/onboarding_service.dart';
import 'package:oruv/components/welcomePages/screenFour.dart';
import 'package:oruv/components/welcomePages/welcomePage.dart';
import 'package:oruv/services/preferences_service.dart';
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

  bool hasCompletedOnboarding = false;
  try {
    hasCompletedOnboarding =
        await PreferencesService.hasCompletedOnboarding();
  } catch (_) {
    hasCompletedOnboarding = false;
  }

  runApp(MyApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class MyApp extends StatefulWidget {
  final bool hasCompletedOnboarding;
  const MyApp({super.key, this.hasCompletedOnboarding = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<Uri> _linkSubscription;
  final AppLinks _appLinks = AppLinks();
  bool _hasNavigatedToResetPassword = false;
  bool _pendingEmailConfirmation = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkHandling();
  }

  void _navigateToResetPassword() {
    if (_hasNavigatedToResetPassword) return;
    _hasNavigatedToResetPassword = true;

    // Use addPostFrameCallback to ensure Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const ResetPasswordScreen(),
        ),
      ).then((_) {
        // Reset flag once user pops/leaves screen
        _hasNavigatedToResetPassword = false;
      });
    });
  }

  void _navigateToHomeAfterConfirm() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (OnboardingData.instance.fullName.isNotEmpty) {
        await OnboardingService.saveOnboardingData();
      }
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    });
  }

  void _handleIncomingUri(Uri uri) async {
    if (uri.scheme != 'oruv') return;

    // 1. If the deep link is for reset-password
    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {
        // Ignored if session is already retrieved or PKCE handled
      }
      _navigateToResetPassword();
      return;
    }

    // 2. If the deep link is for email confirmation (oruv://login-callback)
    if (uri.host == 'login-callback' || uri.path.contains('login-callback')) {
      _pendingEmailConfirmation = true;
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {
        // Ignored if supabase_flutter already exchanged the PKCE code
      }
      if (Supabase.instance.client.auth.currentSession != null) {
        _pendingEmailConfirmation = false;
        _navigateToHomeAfterConfirm();
      }
    }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigateToResetPassword();
      } else if (event == AuthChangeEvent.signedIn && _pendingEmailConfirmation) {
        _pendingEmailConfirmation = false;
        _navigateToHomeAfterConfirm();
      }
    });
  }

  Future<void> _setupDeepLinkHandling() async {
    // Handle link that launched the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {}

    // Listen to incoming links while app was already running/backgrounded
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleIncomingUri(uri);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _linkSubscription.cancel();
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

    final Widget homeScreen;
    if (isLoggedIn) {
      homeScreen = const HomeScreen();
    } else if (widget.hasCompletedOnboarding) {
      homeScreen = const ScreenFour();
    } else {
      homeScreen = const WelcomePage();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Oruv',
      debugShowCheckedModeBanner: false,
      home: homeScreen,
    );
  }
}
