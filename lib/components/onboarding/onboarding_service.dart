import 'package:flutter/foundation.dart';
import 'package:oruv/components/onboarding/onboarding_data.dart';
import 'package:oruv/services/preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  /// Hydrates [OnboardingData.instance] from Supabase Auth metadata and the
  /// `profiles` table (if present) so profile & preferences persist across launches.
  static Future<void> loadOnboardingData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    OnboardingData.instance.reset();

    final meta = user.userMetadata;
    if (meta != null && meta.isNotEmpty) {
      OnboardingData.instance.loadFromMap(meta);
    }

    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) {
        OnboardingData.instance.loadFromMap(profile);
      }
    } catch (e) {
      debugPrint('Profiles table load note: $e');
    }
  }

  /// Saves the collected onboarding data for the currently authenticated user
  /// into both user_metadata and the `profiles` table (if available).
  static Future<void> saveOnboardingData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await PreferencesService.setCompletedOnboarding(true);

    final data = OnboardingData.instance.toMap();

    try {
      // 1. Save directly into Supabase Auth User Metadata
      await client.auth.updateUser(
        UserAttributes(
          data: data,
        ),
      );
    } catch (e) {
      debugPrint('Error updating user metadata: $e');
    }

    try {
      // 2. Also upsert into a public profiles table if the table exists
      await client.from('profiles').upsert({
        'id': user.id,
        ...OnboardingData.instance.toProfileMap(),
      });
    } catch (e) {
      // Profiles table might not be set up yet or RLS policy might differ,
      // user metadata already has the full data safely stored.
      debugPrint('Profiles table upsert note: $e');
    }
  }

  /// Deletes user data and calls the `delete_user_account` RPC in Supabase
  /// to remove the authenticated `auth.users` account.
  /// Invokes the transactional RPC first so `ON DELETE CASCADE` removes all
  /// dependent rows atomically without leaving an orphaned account behind.
  static Future<bool> deleteAccount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return false;

    try {
      await client.rpc('delete_user_account');
      return true;
    } catch (e) {
      debugPrint('delete_user_account RPC failed: $e');
      return false;
    }
  }
}

