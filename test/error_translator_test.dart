import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oruv/services/error_translator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorTranslator.translateAuthError', () {
    test('translates invalid credentials', () {
      const err = AuthException('Invalid login credentials', statusCode: '400');
      expect(
        ErrorTranslator.translateAuthError(err),
        'Incorrect email or password. Please check your credentials and try again.',
      );
    });

    test('translates email not confirmed', () {
      const err = AuthException('Email not confirmed', statusCode: '400');
      expect(
        ErrorTranslator.translateAuthError(err),
        'Please confirm your email address before signing in. Check your inbox for the confirmation link.',
      );
    });

    test('translates user already registered', () {
      const err = AuthException('User already registered', statusCode: '422');
      expect(
        ErrorTranslator.translateAuthError(err),
        'An account with this email address already exists. Please sign in instead.',
      );
    });

    test('translates weak password', () {
      const err = AuthException('Password should be at least 6 characters.', statusCode: '422');
      expect(
        ErrorTranslator.translateAuthError(err),
        'Password must be at least 6 characters long.',
      );
    });

    test('translates rate limit / too many requests', () {
      const err = AuthException(
        'For security purposes, you can only request this once every 60 seconds.',
        statusCode: '429',
      );
      expect(
        ErrorTranslator.translateAuthError(err),
        'Too many attempts. Please wait a moment before trying again.',
      );
    });

    test('translates expired otp / verification token', () {
      const err = AuthException('Email link is invalid or has expired', statusCode: '400');
      expect(
        ErrorTranslator.translateAuthError(err),
        'This verification link is invalid or has expired. Please request a new one.',
      );
    });

    test('translates network SocketException', () {
      const err = SocketException('Failed host lookup: api.supabase.co');
      expect(
        ErrorTranslator.translateAuthError(err),
        'Unable to connect. Please check your internet connection and try again.',
      );
    });

    test('translates technical jargon / database errors to friendly fallback', () {
      const err = AuthException(
        'Database error saving new user: syntax error at or near "SELECT" {code: 500}',
        statusCode: '500',
      );
      expect(
        ErrorTranslator.translateAuthError(err),
        'An unexpected error occurred. Please try again.',
      );
    });

    test('handles null safely', () {
      expect(
        ErrorTranslator.translateAuthError(null),
        'An unexpected error occurred. Please try again.',
      );
    });
  });

  group('ErrorTranslator.translateAppleSignInError', () {
    test('translates Apple authorization codes', () {
      const errFailed = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'Authorization failed',
      );
      expect(
        ErrorTranslator.translateAppleSignInError(errFailed),
        'Apple Sign-In was not successful. Please try again.',
      );

      const errCanceled = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'User cancelled',
      );
      expect(
        ErrorTranslator.translateAppleSignInError(errCanceled),
        'Apple Sign-In was cancelled.',
      );
    });

    test('translates missing identity token error string without raw exception dump', () {
      const err = 'No identity token found from Apple Sign-In.';
      expect(
        ErrorTranslator.translateAppleSignInError(err),
        'Could not retrieve your Apple account credentials. Please try again.',
      );
    });
  });

  group('ErrorTranslator.translateScreenTimeError', () {
    test('translates iOS FamilyControlsError 1 (restricted)', () {
      const raw = 'The operation couldn’t be completed. (FamilyControls.FamilyControlsError error 1.)';
      expect(
        ErrorTranslator.translateScreenTimeError(raw),
        'Screen Time access is restricted on this device (e.g. by Parental Controls or a management profile).',
      );
    });

    test('translates iOS FamilyControlsError 2 (unavailable)', () {
      const raw = 'The operation couldn’t be completed. (FamilyControls.FamilyControlsError error 2.)';
      expect(
        ErrorTranslator.translateScreenTimeError(raw),
        'Screen Time controls are not available on this device.',
      );
    });

    test('translates iOS FamilyControlsError 3 (denied)', () {
      const raw = 'The operation couldn’t be completed. (FamilyControls.FamilyControlsError error 3.)';
      expect(
        ErrorTranslator.translateScreenTimeError(raw),
        'Screen Time access was denied. You can enable it in iOS Settings > Screen Time.',
      );
    });

    test('translates generic denied or canceled messages', () {
      expect(
        ErrorTranslator.translateScreenTimeError('Authorization was denied by user'),
        'Screen Time access was not granted. Please allow access in the system prompt or enable it in Settings.',
      );
    });
  });
}
