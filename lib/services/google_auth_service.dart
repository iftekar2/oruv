import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static GoogleSignIn? _googleSignInInstance;

  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance == null) {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

      _googleSignInInstance = GoogleSignIn(
        clientId: iosClientId != null && iosClientId.isNotEmpty
            ? iosClientId
            : null,
        serverClientId: webClientId != null && webClientId.isNotEmpty
            ? webClientId
            : null,
        scopes: ['email', 'profile'],
      );
    }
    return _googleSignInInstance!;
  }

  /// Signs in or signs up with Google natively and exchanges credentials with Supabase.
  static Future<AuthResponse?> signInWithGoogle(BuildContext context) async {
    try {
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

      if (idToken == null) {
        throw 'No ID Token found from Google Sign-In. Make sure your Web Client ID / Server Client ID is configured.';
      }

      // 3. Authenticate with Supabase using ID token
      final authResponse =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return authResponse;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('No ID Token')
                  ? e.toString()
                  : 'Google Sign-In failed: $e',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return null;
    }
  }

  /// Signs out from Google if signed in
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}

