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
import 'package:oruv/services/account_lifecycle_service.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:oruv/services/preferences_service.dart';
import 'package:oruv/services/secure_supabase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Note: .env file not loaded or not bundled: $e');
  }

  const defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const defineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON');

  final supabaseUrl =
      (dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
              ? dotenv.env['SUPABASE_URL']
              : defineSupabaseUrl)
          ?.trim() ??
      '';

  final supabaseAnonKey =
      ((dotenv.env['SUPABASE_ANON'] ?? dotenv.env['SUPABASE_ANON_KEY'])
                  ?.trim()
                  .isNotEmpty ==
              true
          ? (dotenv.env['SUPABASE_ANON'] ?? dotenv.env['SUPABASE_ANON_KEY'])
          : defineSupabaseAnonKey)
      ?.trim() ??
      '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    AccountLifecycleService.registerSupabaseUrl(supabaseUrl);
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(
          persistSessionKey: SecureLocalStorage.sessionKeyForUrl(supabaseUrl),
        ),
        pkceAsyncStorage: const SecureGotrueAsyncStorage(),
        // Enforce app-level pending-transaction & PKCE checks before exchanging URIs.
        detectSessionInUri: false,
      ),
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

  void _showAuthLinkError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    final auth = Supabase.instance.client.auth;
    final validation = await AuthRedirectService.validateIncomingUri(
      uri,
      currentUserId: auth.currentUser?.id,
    );

    if (!validation.isValid) {
      debugPrint('Rejected auth deep link: ${validation.rejectionReason}');
      return;
    }

    if (validation.flow == AuthRedirectFlow.resetPassword) {
      try {
        await auth.getSessionFromUrl(uri);
        await AuthRedirectService.clearPendingFlow(
          AuthRedirectFlow.resetPassword,
        );
        if (auth.currentSession != null) {
          _navigateToResetPassword();
        } else {
          _showAuthLinkError(
            'Password reset link could not be verified. Please request a new one.',
          );
        }
      } catch (e) {
        debugPrint('Reset-password deep link exchange failed: $e');
        _showAuthLinkError(
          'Password reset link is invalid or expired. Please request a new one.',
        );
      }
      return;
    }

    if (validation.flow == AuthRedirectFlow.loginCallback) {
      _pendingEmailConfirmation = true;
      try {
        await auth.getSessionFromUrl(uri);
        await AuthRedirectService.clearPendingFlow(
          AuthRedirectFlow.loginCallback,
        );
        if (auth.currentSession != null) {
          _pendingEmailConfirmation = false;
          _navigateToHomeAfterConfirm();
        }
      } catch (e) {
        _pendingEmailConfirmation = false;
        debugPrint('Login-callback deep link exchange failed: $e');
        _showAuthLinkError(
          'Sign-in verification link is invalid or expired. Please try again.',
        );
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
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Oruv',
      debugShowCheckedModeBanner: false,
      home: homeScreen,
    );
  }
}
