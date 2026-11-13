import 'package:flutter/foundation.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/components/onboarding/onboarding_service.dart';
import 'package:oruv/services/auth_redirect_service.dart';
import 'package:oruv/services/google_auth_service.dart';
import 'package:oruv/services/preferences_service.dart';
import 'package:oruv/services/schedule_service.dart';
import 'package:oruv/services/screen_time_service.dart';
import 'package:oruv/services/secure_supabase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared account lifecycle orchestrator for sign-out and account deletion.
/// Guarantees local in-memory, preference, and native Screen Time state are
/// wiped deterministically regardless of network availability.
class AccountLifecycleService {
  static String? _configuredSupabaseUrl;

  static void registerSupabaseUrl(String url) {
    _configuredSupabaseUrl = url;
  }

  /// Resets in-memory onboarding state, ScheduleService dedup signatures,
  /// user-scoped SharedPreferences, and native Screen Time shields/telemetry.
  static Future<void> resetLocalAccountState({
    required bool clearOnboardingFlag,
    required bool clearScreenTimeSelection,
  }) async {
    OnboardingData.instance.reset();
    ScheduleService.resetLocalCaches();

    await AuthRedirectService.clearAllPendingFlows();
    await ScreenTimeService.resetLocalAccountState(
      clearSelection: clearScreenTimeSelection,
    );
    await PreferencesService.resetUserScopedPreferences(
      clearOnboarding: clearOnboardingFlag,
    );
    if (!clearOnboardingFlag) {
      await PreferencesService.setCompletedOnboarding(true);
    }
  }

  static Future<void> _forceClearPersistedSession() async {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    final url = _configuredSupabaseUrl;
    if (url != null && url.isNotEmpty) {
      await SecureLocalStorage(
        persistSessionKey: SecureLocalStorage.sessionKeyForUrl(url),
      ).removePersistedSession();
    }
  }

  /// Signs the user out cleanly. Always resets local/native state first so
  /// transient network errors during remote sign-out cannot leave prior-user
  /// data, shields, or tokens active on the device.
  static Future<void> signOut() async {
    await resetLocalAccountState(
      clearOnboardingFlag: false,
      clearScreenTimeSelection: true,
    );

    await GoogleAuthService.signOut();

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Remote Supabase signOut note: $e');
      await _forceClearPersistedSession();
    }

    if (Supabase.instance.client.auth.currentSession != null) {
      await _forceClearPersistedSession();
    }
  }

  /// Deletes the authenticated account server-side before wiping local state.
  /// Returns `false` and aborts local cleanup/navigation if the backend deletion
  /// RPC fails so callers can surface an accurate error to the user.
  static Future<bool> deleteAccountAndSignOut() async {
    final deleted = await OnboardingService.deleteAccount();
    if (!deleted) {
      return false;
    }

    await resetLocalAccountState(
      clearOnboardingFlag: true,
      clearScreenTimeSelection: true,
    );

    await GoogleAuthService.signOut();
    await _forceClearPersistedSession();
    return true;
  }
}

