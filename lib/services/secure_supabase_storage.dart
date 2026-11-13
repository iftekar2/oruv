import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared encrypted key-value storage wrapper backed by Android Keystore AES-GCM
/// and iOS Keychain (`first_unlock_this_device`, non-synchronizable).
const FlutterSecureStorage oruvSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  ),
);

/// Encrypted [LocalStorage] implementation for Supabase Auth sessions,
/// replacing plaintext SharedPreferences / NSUserDefaults persistence and
/// migrating any pre-existing plaintext session out of SharedPreferences.
class SecureLocalStorage extends LocalStorage {
  final String persistSessionKey;
  final FlutterSecureStorage _storage;

  const SecureLocalStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? oruvSecureStorage;

  static String sessionKeyForUrl(String supabaseUrl) {
    final host = Uri.tryParse(supabaseUrl)?.host ?? '';
    final ref = host.isNotEmpty ? host.split('.').first : 'oruv';
    return 'sb-$ref-auth-token';
  }

  @override
  Future<void> initialize() async {
    await _migrateFromSharedPreferencesIfPresent();
  }

  Future<void> _migrateFromSharedPreferencesIfPresent() async {
    try {
      final existingSecure = await _storage.read(key: persistSessionKey);
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(persistSessionKey);
      if (legacy != null) {
        if (existingSecure == null || existingSecure.isEmpty) {
          await _storage.write(key: persistSessionKey, value: legacy);
        }
        await prefs.remove(persistSessionKey);
      }
      if (prefs.containsKey(supabasePersistSessionKey)) {
        await prefs.remove(supabasePersistSessionKey);
      }
    } catch (e) {
      debugPrint('SecureLocalStorage migration note: $e');
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      final value = await _storage.read(key: persistSessionKey);
      return value != null && value.isNotEmpty;
    } catch (e) {
      debugPrint('SecureLocalStorage.hasAccessToken error: $e');
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      final secureValue = await _storage.read(key: persistSessionKey);
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
      await _migrateFromSharedPreferencesIfPresent();
      return await _storage.read(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureLocalStorage.accessToken error: $e');
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: persistSessionKey);
    } catch (e) {
      debugPrint('SecureLocalStorage.removePersistedSession error: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(persistSessionKey);
      await prefs.remove(supabasePersistSessionKey);
    } catch (_) {}
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: persistSessionKey,
      value: persistSessionString,
    );
  }
}

/// Encrypted [GotrueAsyncStorage] implementation for PKCE code verifiers so
/// short-lived PKCE secrets are never written to plaintext SharedPreferences.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  final FlutterSecureStorage _storage;

  const SecureGotrueAsyncStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? oruvSecureStorage;

  @override
  Future<String?> getItem({required String key}) async {
    try {
      final secureValue = await _storage.read(key: key);
      if (secureValue != null) {
        return secureValue;
      }
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(key);
      if (legacy != null) {
        await _storage.write(key: key, value: legacy);
        await prefs.remove(key);
        return legacy;
      }
      return null;
    } catch (e) {
      debugPrint('SecureGotrueAsyncStorage.getItem error: $e');
      return null;
    }
  }

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureGotrueAsyncStorage.removeItem error: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
}

