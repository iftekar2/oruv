import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyMindfulBreakDefaultMinutes =
      'mindful_break_default_minutes';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

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

  /// Default mindful break duration in minutes (5, 10, or 15).
  static Future<int> getMindfulBreakDefaultMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getInt(_keyMindfulBreakDefaultMinutes) ?? 5;
      return (val == 5 || val == 10 || val == 15) ? val : 5;
    } catch (e) {
      debugPrint('PreferencesService.getMindfulBreakDefaultMinutes error: $e');
      return 5;
    }
  }

  /// Saves default mindful break duration in minutes.
  static Future<void> setMindfulBreakDefaultMinutes(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMindfulBreakDefaultMinutes, minutes);
    } catch (e) {
      debugPrint('PreferencesService.setMindfulBreakDefaultMinutes error: $e');
    }
  }

  /// Whether focus notifications/reminders are enabled.
  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNotificationsEnabled) ?? false;
    } catch (e) {
      debugPrint('PreferencesService.getNotificationsEnabled error: $e');
      return false;
    }
  }

  /// Sets whether focus notifications/reminders are enabled.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationsEnabled, enabled);
    } catch (e) {
      debugPrint('PreferencesService.setNotificationsEnabled error: $e');
    }
  }
}

