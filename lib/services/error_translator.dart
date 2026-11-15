import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates raw system, SDK, backend, and platform errors into clear,
/// actionable, user-friendly error messages.
class ErrorTranslator {
  const ErrorTranslator._();

  /// Translates Supabase / authentication errors into human-readable messages.
  static String translateAuthError(
    dynamic error, {
    String fallback = 'An unexpected error occurred. Please try again.',
  }) {
    if (error == null) return fallback;

    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final msg = error.message.toLowerCase();

      // Check error code first, then message contents
      if (code == 'invalid_credentials' ||
          code == 'invalid_grant' ||
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid_grant')) {
        return 'Incorrect email or password. Please check your credentials and try again.';
      }

      if (code == 'email_not_confirmed' ||
          msg.contains('email not confirmed')) {
        return 'Please confirm your email address before signing in. Check your inbox for the confirmation link.';
      }

      if (code == 'user_already_exists' ||
          msg.contains('user already registered') ||
          msg.contains('already registered') ||
          msg.contains('email already in use')) {
        return 'An account with this email address already exists. Please sign in instead.';
      }

      if (code == 'weak_password' ||
          msg.contains('password should be at least') ||
          msg.contains('password is too short')) {
        return 'Password must be at least 6 characters long.';
      }

      if (code == 'same_password' ||
          msg.contains('same as the old password') ||
          msg.contains('same password')) {
        return 'New password cannot be the same as your old password.';
      }

      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('for security purposes')) {
        return 'Too many attempts. Please wait a moment before trying again.';
      }

      if (code == 'user_not_found' || msg.contains('user not found')) {
        return 'No account was found with this email address.';
      }

      if (code == 'signup_disabled' || msg.contains('signup is disabled')) {
        return 'Account registration is currently unavailable. Please try again later or contact support.';
      }

      if (code == 'validation_failed' ||
          msg.contains('unable to validate email') ||
          msg.contains('invalid format')) {
        return 'Please enter a valid email address.';
      }

      if (code == 'otp_expired' ||
          msg.contains('token has expired') ||
          msg.contains('token is invalid') ||
          msg.contains('link is invalid or has expired') ||
          msg.contains('recovery token')) {
        return 'This verification link is invalid or has expired. Please request a new one.';
      }

      if (code == 'bad_jwt' ||
          code == 'session_expired' ||
          msg.contains('jwt expired') ||
          msg.contains('session expired')) {
        return 'Your session has expired. Please sign in again.';
      }

      if (code == 'email_provider_disabled' ||
          code == 'provider_disabled' ||
          msg.contains('provider is not enabled')) {
        return 'This sign-in method is temporarily unavailable. Please try another sign-in option.';
      }

      // Check for network errors embedded in AuthException
      if (_isNetworkError(msg)) {
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      }

      // If the error message from Supabase is technical jargon (contains internal IDs, HTTP codes, brackets),
      // return a friendly message rather than exposing backend implementation details.
      if (_isTechnicalJargon(error.message)) {
        return fallback;
      }

      // If it's a reasonably clean sentence, ensure proper capitalization and return.
      return _cleanSentence(error.message, fallback: fallback);
    }

    if (error is SocketException ||
        error is HttpException ||
        _isNetworkError(error.toString())) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    if (error is PlatformException) {
      if (error.code == 'network_error' || _isNetworkError(error.message ?? '')) {
        return 'Network connection error. Please check your internet connection and try again.';
      }
      return fallback;
    }

    final rawStr = error.toString();
    if (_isNetworkError(rawStr)) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    return fallback;
  }

  /// Translates Apple Sign-In exceptions into human-readable messages.
  static String translateAppleSignInError(
    dynamic error, {
    String fallback = 'Apple Sign-In could not be completed. Please try again.',
  }) {
    if (error == null) return fallback;

    if (error is SignInWithAppleAuthorizationException) {
      switch (error.code) {
        case AuthorizationErrorCode.canceled:
          return 'Apple Sign-In was cancelled.';
        case AuthorizationErrorCode.failed:
          return 'Apple Sign-In was not successful. Please try again.';
        case AuthorizationErrorCode.invalidResponse:
          return 'Received an invalid response from Apple. Please try again.';
        case AuthorizationErrorCode.notHandled:
          return 'The Apple Sign-In request could not be processed. Please try again.';
        case AuthorizationErrorCode.notInteractive:
          return 'Apple Sign-In is unavailable. Please check your Apple ID settings.';
        case AuthorizationErrorCode.unknown:
          return 'Apple Sign-In encountered an unexpected issue. Please try again.';
      }
    }

    if (error is AuthException) {
      return translateAuthError(error, fallback: fallback);
    }

    final str = error.toString().toLowerCase();

    if (str.contains('no identity token') || str.contains('missing identity token')) {
      return 'Could not retrieve your Apple account credentials. Please try again.';
    }

    if (_isNetworkError(str)) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    return fallback;
  }

  /// Translates Screen Time permission and FamilyControls errors into human-readable messages.
  static String translateScreenTimeError(
    dynamic error, {
    String fallback = 'Screen Time access could not be connected. Please try again or check your iOS Settings.',
  }) {
    if (error == null) {
      return 'Screen Time access was not granted. Please tap Allow on the system prompt.';
    }

    if (error is MissingPluginException) {
      return 'Screen Time features are temporarily unavailable. Please restart the app.';
    }

    final msg = error.toString().toLowerCase();

    // iOS FamilyControlsError codes:
    // 1: restricted
    // 2: unavailable
    // 3: denied
    if (msg.contains('familycontrols')) {
      if (msg.contains('error 1') || msg.contains('restricted')) {
        return 'Screen Time access is restricted on this device (e.g. by Parental Controls or a management profile).';
      }
      if (msg.contains('error 2') || msg.contains('unavailable')) {
        return 'Screen Time controls are not available on this device.';
      }
      if (msg.contains('error 3') || msg.contains('denied')) {
        return 'Screen Time access was denied. You can enable it in iOS Settings > Screen Time.';
      }
      return 'Screen Time access could not be authorized. Please check your Screen Time settings in iOS Settings.';
    }

    if (msg.contains('ios 16') || msg.contains('requires ios')) {
      return 'Screen Time features require iOS 16.0 or newer.';
    }

    if (msg.contains('restricted')) {
      return 'Screen Time access is restricted on this device.';
    }

    if (msg.contains('denied') ||
        msg.contains('not granted') ||
        msg.contains('cancelled') ||
        msg.contains('canceled')) {
      return 'Screen Time access was not granted. Please allow access in the system prompt or enable it in Settings.';
    }

    if (msg.contains('simulator')) {
      return 'Screen Time features require a physical iOS device.';
    }

    if (msg.contains('missingpluginexception') || msg.contains('rebuild')) {
      return 'Screen Time features are temporarily unavailable. Please restart the app.';
    }

    return fallback;
  }

  static bool _isNetworkError(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('networkrequesterror') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('handshakeexception') ||
        lower.contains('timed out') ||
        lower.contains('timeoutexception') ||
        lower.contains('network error') ||
        lower.contains('network_error') ||
        lower.contains('offline');
  }

  static bool _isTechnicalJargon(String text) {
    final lower = text.toLowerCase();
    return text.contains('{') ||
        text.contains('}') ||
        text.contains('[') ||
        text.contains(']') ||
        lower.contains('exception:') ||
        lower.contains('sub claim') ||
        lower.contains('jwt') ||
        lower.contains('column') ||
        lower.contains('relation') ||
        lower.contains('syntax error') ||
        lower.contains('status code') ||
        lower.contains('http') ||
        lower.contains('database error') ||
        lower.contains('internal server error') ||
        lower.contains('pg_') ||
        lower.contains('sql') ||
        lower.contains('invalid_grant');
  }

  static String _cleanSentence(String text, {required String fallback}) {
    var trimmed = text.trim();
    if (trimmed.isEmpty) return fallback;
    if (!trimmed.endsWith('.') && !trimmed.endsWith('!') && !trimmed.endsWith('?')) {
      trimmed = '$trimmed.';
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}
