import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  /// Returns whether the user has already completed or passed the onboarding flow.
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
    } catch (e) {
      debugPrint('PreferencesService.hasCompletedOnboarding error: $e');
      return false;
    }
  }

  /// Sets whether the onboarding flow has been completed.
  static Future<void> setCompletedOnboarding(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCompletedOnboarding, completed);
    } catch (e) {
      debugPrint('PreferencesService.setCompletedOnboarding error: $e');
    }
  }

  /// Clears onboarding status (useful for testing or full app resets).
  static Future<void> clearOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasCompletedOnboarding);
    } catch (e) {
      debugPrint('PreferencesService.clearOnboarding error: $e');
    }
  }
}

