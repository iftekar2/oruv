import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static GoogleSignIn? _googleSignInInstance;

  static const bool _usePkceOAuth =
      bool.fromEnvironment('GOOGLE_USE_PKCE_OAUTH', defaultValue: false);

  static const String _defineWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String _defineIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static String? _resolveWebClientId() {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return _defineWebClientId.trim().isNotEmpty ? _defineWebClientId.trim() : null;
  }

  static String? _resolveIosClientId() {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }
    return _defineIosClientId.trim().isNotEmpty ? _defineIosClientId.trim() : null;
  }

  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance == null) {
      final webClientId = _resolveWebClientId();
      final iosClientId = _resolveIosClientId();

      _googleSignInInstance = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );
    }
    return _googleSignInInstance!;
  }

  static Map<String, dynamic>? _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  /// Validates basic structural claims of the Google ID token returned by the
  /// native Google Sign-In SDK (`iss`, `aud` matching configured client IDs,
  /// non-expired `exp`, and verified email). Server-side signature and nonce
  /// verification remain enforced by Supabase Auth.
  @visibleForTesting
  static bool validateIdTokenClaims(
    String idToken, {
    Set<String>? allowedAudiences,
  }) {
    final payload = _decodeJwtPayload(idToken);
    if (payload == null) return false;

    final iss = payload['iss']?.toString() ?? '';
    if (iss != 'https://accounts.google.com' && iss != 'accounts.google.com') {
      return false;
    }

    final audiences = allowedAudiences ?? _configuredAudiences();
    final aud = payload['aud']?.toString() ?? '';
    if (audiences.isNotEmpty && !audiences.contains(aud)) {
      return false;
    }

    final exp = payload['exp'];
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (exp is! num || exp <= nowSeconds) {
      return false;
    }

    if (payload['email_verified'] == false) {
      return false;
    }

    return true;
  }

  static Set<String> _configuredAudiences() {
    final web = _resolveWebClientId();
    final ios = _resolveIosClientId();
    return <String>{
      if (web != null && web.isNotEmpty) web,
      if (ios != null && ios.isNotEmpty) ios,
    };
  }

  /// Optional browser-based Google OAuth PKCE flow (`--dart-define=GOOGLE_USE_PKCE_OAUTH=true`),
  /// binding the full sign-in exchange to a local PKCE `code_verifier` stored in
  /// encrypted storage rather than passing a client-obtained Google ID token.
  static Future<bool> signInWithGoogleOAuth() async {
    await AuthRedirectService.markPendingFlow(AuthRedirectFlow.loginCallback);
    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AuthRedirectService.emailConfirmRedirectUrl,
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        await AuthRedirectService.clearPendingFlow(
          AuthRedirectFlow.loginCallback,
        );
      }
      return launched;
    } catch (_) {
      await AuthRedirectService.clearPendingFlow(
        AuthRedirectFlow.loginCallback,
      );
      rethrow;
    }
  }

  /// Signs in or signs up with Google natively and exchanges credentials with Supabase.
  /// Note: `google_sign_in` v6 / `GoogleSignIn` iOS SDK v8 does not expose a
  /// caller-controlled OIDC `nonce` parameter; either enable "Skip nonce checks"
  /// alongside strict Authorized Client IDs in Supabase Auth for native sign-in,
  /// or set `--dart-define=GOOGLE_USE_PKCE_OAUTH=true` to use Supabase PKCE OAuth.
  static Future<AuthResponse?> signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      if (_usePkceOAuth) {
        await signInWithGoogleOAuth();
        return null;
      }

      // 1. Trigger the native Google Sign In prompt
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in dialog
        return null;
      }

      // 2. Obtain auth details (idToken and accessToken)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        throw const FormatException('missing_google_id_token');
      }

      if (!validateIdTokenClaims(idToken)) {
        throw const FormatException('invalid_google_id_token_claims');
      }

      // 3. Authenticate with Supabase using ID token
      final authResponse =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return authResponse;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      debugPrint('Google Sign-In PlatformException: ${e.code} ${e.message}');
      _showSafeError(
        messenger,
        'Google Sign-In could not be completed. Please try again.',
      );
      return null;
    } on AuthException catch (e) {
      debugPrint('Google Sign-In AuthException: ${e.message}');
      _showSafeError(messenger, e.message);
      return null;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _showSafeError(
        messenger,
        'Google Sign-In failed. Please try again.',
      );
      return null;
    }
  }

  static void _showSafeError(
    ScaffoldMessengerState? messenger,
    String message,
  ) {
    if (messenger == null || !messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  /// Signs out from Google if signed in
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
