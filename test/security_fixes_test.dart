import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oruv/components/home/models/home_models.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/services/account_lifecycle_service.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:oruv/services/google_auth_service.dart';
import 'package:oruv/services/preferences_service.dart';
import 'package:oruv/services/secure_supabase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _buildUnsignedJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.sig';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureStoreBacking;

  setUp(() {
    secureStoreBacking = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(secureStoreBacking);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    OnboardingData.instance.reset();
  });

  group('SecureLocalStorage & SecureGotrueAsyncStorage', () {
    test('migrates legacy SharedPreferences session and removes plaintext copy',
        () async {
      const sessionKey = 'sb-oruvtest-auth-token';
      const legacySessionJson = '{"access_token":"secret_jwt"}';
      SharedPreferences.setMockInitialValues(<String, Object>{
        sessionKey: legacySessionJson,
        'SUPABASE_PERSIST_SESSION_KEY': legacySessionJson,
      });

      const storage = SecureLocalStorage(
        persistSessionKey: sessionKey,
        storage: FlutterSecureStorage(),
      );
      await storage.initialize();

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), equals(legacySessionJson));
      expect(secureStoreBacking[sessionKey], equals(legacySessionJson));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(sessionKey), isFalse);
      expect(prefs.containsKey('SUPABASE_PERSIST_SESSION_KEY'), isFalse);

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(secureStoreBacking.containsKey(sessionKey), isFalse);
    });

    test('migrates and deletes PKCE code_verifier in encrypted storage',
        () async {
      const verifierKey = 'sb-oruvtest-auth-token-code-verifier';
      SharedPreferences.setMockInitialValues(<String, Object>{
        verifierKey: 'verifier_123',
      });

      const pkceStorage = SecureGotrueAsyncStorage(
        storage: FlutterSecureStorage(),
      );
      expect(await pkceStorage.getItem(key: verifierKey), equals('verifier_123'));
      expect(secureStoreBacking[verifierKey], equals('verifier_123'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(verifierKey), isFalse);

      await pkceStorage.removeItem(key: verifierKey);
      expect(await pkceStorage.getItem(key: verifierKey), isNull);
    });
  });

  group('AuthRedirectService validation', () {
    test('rejects unsolicited deep links without a pending local flow',
        () async {
      final resetResult = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://reset-password?code=pkce_code_1'),
        currentUserId: null,
      );
      expect(resetResult.isValid, isFalse);
      expect(resetResult.rejectionReason, equals('no_pending_auth_flow'));

      final loginResult = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://login-callback?code=pkce_code_2'),
        currentUserId: null,
      );
      expect(loginResult.isValid, isFalse);
      expect(loginResult.rejectionReason, equals('no_pending_auth_flow'));
    });

    test('rejects implicit access_token grants and missing PKCE code',
        () async {
      await AuthRedirectService.markPendingFlow(
        AuthRedirectFlow.loginCallback,
      );

      final implicitFragment = await AuthRedirectService.validateIncomingUri(
        Uri.parse(
          'oruv://login-callback#access_token=attacker&refresh_token=attacker',
        ),
        currentUserId: null,
      );
      expect(implicitFragment.isValid, isFalse);
      expect(
        implicitFragment.rejectionReason,
        equals('implicit_token_rejected'),
      );

      final missingCode = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://login-callback'),
        currentUserId: null,
      );
      expect(missingCode.isValid, isFalse);
      expect(missingCode.rejectionReason, equals('missing_pkce_code'));
    });

    test('rejects login-callback session overwrite when signed in as another user',
        () async {
      await AuthRedirectService.markPendingFlow(
        AuthRedirectFlow.loginCallback,
      );

      final result = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://login-callback?code=pkce_code_123'),
        currentUserId: 'existing-user-id',
      );
      expect(result.isValid, isFalse);
      expect(result.rejectionReason, equals('active_session_conflict'));
    });

    test('accepts valid PKCE reset-password and login-callback when flow pending',
        () async {
      await AuthRedirectService.markPendingFlow(
        AuthRedirectFlow.resetPassword,
        userId: 'user-1',
      );
      final resetResult = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://reset-password?code=pkce_reset_1'),
        currentUserId: 'user-1',
      );
      expect(resetResult.isValid, isTrue);
      expect(resetResult.flow, equals(AuthRedirectFlow.resetPassword));

      await AuthRedirectService.markPendingFlow(
        AuthRedirectFlow.loginCallback,
      );
      final signupResult = await AuthRedirectService.validateIncomingUri(
        Uri.parse('oruv://login-callback?code=pkce_signup_1'),
        currentUserId: null,
      );
      expect(signupResult.isValid, isTrue);
      expect(signupResult.flow, equals(AuthRedirectFlow.loginCallback));
    });
  });

  group('AccountLifecycleService & PreferencesService state isolation', () {
    test('clears user-scoped preferences and OnboardingData on logout/delete',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'has_completed_onboarding': true,
        'mindful_break_default_minutes': 15,
        'notifications_enabled': true,
      });

      OnboardingData.instance.fullName = 'Alice Example';
      OnboardingData.instance.occupation = 'Engineer';
      OnboardingData.instance.age = 31;
      OnboardingData.instance.screenTimeAuthorized = true;

      await AccountLifecycleService.resetLocalAccountState(
        clearOnboardingFlag: false,
        clearScreenTimeSelection: true,
      );

      expect(OnboardingData.instance.fullName, isEmpty);
      expect(OnboardingData.instance.occupation, isEmpty);
      expect(OnboardingData.instance.age, isNull);
      expect(OnboardingData.instance.screenTimeAuthorized, isFalse);
      expect(await PreferencesService.hasCompletedOnboarding(), isTrue);
      expect(await PreferencesService.getMindfulBreakDefaultMinutes(), equals(5));
      expect(await PreferencesService.getNotificationsEnabled(), isFalse);

      await AccountLifecycleService.resetLocalAccountState(
        clearOnboardingFlag: true,
        clearScreenTimeSelection: true,
      );
      expect(await PreferencesService.hasCompletedOnboarding(), isFalse);
    });
  });

  group('Google ID token structural claim verification helper', () {
    test('rejects expired or unverified Google ID tokens', () {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final validToken = _buildUnsignedJwt({
        'iss': 'https://accounts.google.com',
        'aud': 'client-123',
        'exp': now + 300,
        'email_verified': true,
      });
      final expiredToken = _buildUnsignedJwt({
        'iss': 'https://accounts.google.com',
        'aud': 'client-123',
        'exp': now - 60,
        'email_verified': true,
      });
      final badIssuer = _buildUnsignedJwt({
        'iss': 'https://evil.example',
        'aud': 'client-123',
        'exp': now + 300,
        'email_verified': true,
      });

      expect(
        GoogleAuthService.validateIdTokenClaims(
          validToken,
          allowedAudiences: {'client-123'},
        ),
        isTrue,
      );
      expect(
        GoogleAuthService.validateIdTokenClaims(
          expiredToken,
          allowedAudiences: {'client-123'},
        ),
        isFalse,
      );
      expect(
        GoogleAuthService.validateIdTokenClaims(
          badIssuer,
          allowedAudiences: {'client-123'},
        ),
        isFalse,
      );
    });
  });

  group('ScheduleRuleModel.toSupabaseMap', () {
    test('includes user_id alongside id for composite (user_id, id) key', () {
      const rule = ScheduleRuleModel(
        id: 'work_time',
        title: 'Work Time',
        startTime: '9:00 AM',
        endTime: '5:00 PM',
        enforcementMode: 'Strict enforcement mode',
        isActive: true,
      );
      final map = rule.toSupabaseMap('user-abc');
      expect(map['id'], equals('work_time'));
      expect(map['user_id'], equals('user-abc'));
    });
  });

  group('ScheduleRuleModel overlap checks', () {
    test('Evening Wind Down (8:00 PM - 6:00 AM) does not overlap with Morning Clarity (6:30 AM - 8:30 AM)', () {
      const eveningWindDown = ScheduleRuleModel(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        startTime: '8:00 PM',
        endTime: '6:00 AM',
        enforcementMode: 'Strict enforcement mode',
        isActive: true,
      );
      const morningClarity = ScheduleRuleModel(
        id: 'morning_clarity',
        title: 'Morning Clarity',
        startTime: '6:30 AM',
        endTime: '8:30 AM',
        enforcementMode: 'Gentle reminder mode',
        isActive: true,
      );

      expect(eveningWindDown.overlapsWith(morningClarity), isFalse);
      expect(morningClarity.overlapsWith(eveningWindDown), isFalse);
    });

    test('Old Evening Wind Down (8:00 PM - 7:00 AM) overlaps with Morning Clarity (6:30 AM - 8:30 AM)', () {
      const oldEveningWindDown = ScheduleRuleModel(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        startTime: '8:00 PM',
        endTime: '7:00 AM',
        enforcementMode: 'Strict enforcement mode',
        isActive: true,
      );
      const morningClarity = ScheduleRuleModel(
        id: 'morning_clarity',
        title: 'Morning Clarity',
        startTime: '6:30 AM',
        endTime: '8:30 AM',
        enforcementMode: 'Gentle reminder mode',
        isActive: true,
      );

      expect(oldEveningWindDown.overlapsWith(morningClarity), isTrue);
      expect(morningClarity.overlapsWith(oldEveningWindDown), isTrue);
    });
  });
}
