import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oruv/services/secure_supabase_storage.dart';

enum AuthRedirectFlow {
  resetPassword,
  loginCallback,
}

class AuthDeepLinkValidation {
  final bool isValid;
  final AuthRedirectFlow? flow;
  final String? rejectionReason;

  const AuthDeepLinkValidation({
    required this.isValid,
    this.flow,
    this.rejectionReason,
  });

  const AuthDeepLinkValidation.rejected(this.rejectionReason)
      : isValid = false,
        flow = null;

  const AuthDeepLinkValidation.accepted(this.flow)
      : isValid = true,
        rejectionReason = null;
}

/// Manages auth redirect URLs (configurable HTTPS Universal/App Links base URL
/// with custom scheme fallback) and validates incoming auth deep links against
/// locally initiated pending transactions and PKCE constraints.
class AuthRedirectService {
  static const String _customScheme = 'oruv';
  static const String resetPasswordHost = 'reset-password';
  static const String loginCallbackHost = 'login-callback';
  static const String _pendingFlowStoragePrefix = 'oruv_pending_auth_flow_';
  static const Duration _pendingFlowTtl = Duration(minutes: 30);

  static const String _defineRedirectBaseUrl =
      String.fromEnvironment('AUTH_REDIRECT_BASE_URL');

  static Uri? _resolveHttpsBaseUri() {
    String raw = _defineRedirectBaseUrl.trim();
    if (raw.isEmpty) {
      try {
        if (dotenv.isInitialized) {
          raw = (dotenv.env['AUTH_REDIRECT_BASE_URL'] ?? '').trim();
        }
      } catch (_) {}
    }
    if (raw.isEmpty) return null;

    final parsed = Uri.tryParse(raw);
    if (parsed == null ||
        parsed.scheme != 'https' ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      return null;
    }
    return parsed;
  }

  static String get resetPasswordRedirectUrl {
    final httpsBase = _resolveHttpsBaseUri();
    if (httpsBase != null) {
      return httpsBase.replace(path: '/$resetPasswordHost').toString();
    }
    return '$_customScheme://$resetPasswordHost';
  }

  static String get emailConfirmRedirectUrl {
    final httpsBase = _resolveHttpsBaseUri();
    if (httpsBase != null) {
      return httpsBase.replace(path: '/$loginCallbackHost').toString();
    }
    return '$_customScheme://$loginCallbackHost';
  }

  static String _storageKeyFor(AuthRedirectFlow flow) =>
      '$_pendingFlowStoragePrefix${flow.name}';

  /// Records that the local app instance initiated an email auth transaction so
  /// unexpected unsolicited auth deep links can be rejected.
  static Future<void> markPendingFlow(
    AuthRedirectFlow flow, {
    String? userId,
  }) async {
    final payload = jsonEncode({
      'issuedAtMs': DateTime.now().toUtc().millisecondsSinceEpoch,
      if (userId != null) 'userId': userId,
    });
    await oruvSecureStorage.write(key: _storageKeyFor(flow), value: payload);
  }

  static Future<void> clearPendingFlow(AuthRedirectFlow flow) async {
    await oruvSecureStorage.delete(key: _storageKeyFor(flow));
  }

  static Future<void> clearAllPendingFlows() async {
    await clearPendingFlow(AuthRedirectFlow.resetPassword);
    await clearPendingFlow(AuthRedirectFlow.loginCallback);
  }

  static Future<({bool active, String? initiatedUserId})> _readPendingFlow(
    AuthRedirectFlow flow,
  ) async {
    final raw = await oruvSecureStorage.read(key: _storageKeyFor(flow));
    if (raw == null || raw.isEmpty) {
      return (active: false, initiatedUserId: null);
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final issuedAtMs = decoded['issuedAtMs'] as int? ?? 0;
      final age = DateTime.now().toUtc().millisecondsSinceEpoch - issuedAtMs;
      if (age < 0 || age > _pendingFlowTtl.inMilliseconds) {
        await clearPendingFlow(flow);
        return (active: false, initiatedUserId: null);
      }
      return (
        active: true,
        initiatedUserId: decoded['userId'] as String?,
      );
    } catch (_) {
      await clearPendingFlow(flow);
      return (active: false, initiatedUserId: null);
    }
  }

  static AuthRedirectFlow? matchFlow(Uri uri) {
    final httpsBase = _resolveHttpsBaseUri();
    final isCustomScheme = uri.scheme == _customScheme;
    final isConfiguredHttps = httpsBase != null &&
        uri.scheme == 'https' &&
        uri.host.toLowerCase() == httpsBase.host.toLowerCase();

    if (!isCustomScheme && !isConfiguredHttps) {
      return null;
    }

    if (isCustomScheme) {
      if (uri.host == resetPasswordHost ||
          (uri.host.isEmpty && uri.path == '/$resetPasswordHost')) {
        return AuthRedirectFlow.resetPassword;
      }
      if (uri.host == loginCallbackHost ||
          (uri.host.isEmpty && uri.path == '/$loginCallbackHost')) {
        return AuthRedirectFlow.loginCallback;
      }
      return null;
    }

    final normalizedPath = uri.path.replaceAll(RegExp(r'^/+|/+$'), '');
    if (normalizedPath == resetPasswordHost) {
      return AuthRedirectFlow.resetPassword;
    }
    if (normalizedPath == loginCallbackHost) {
      return AuthRedirectFlow.loginCallback;
    }
    return null;
  }

  /// Validates an incoming auth redirect URI before passing it to Supabase:
  /// - Only accepts exact `oruv://` hosts or configured HTTPS routes
  /// - Requires PKCE `code` parameter and rejects implicit `access_token` grants
  /// - Requires a matching unexpired local pending transaction
  /// - Prevents an unsolicited `login-callback` from overwriting an existing
  ///   active session owned by another user.
  static Future<AuthDeepLinkValidation> validateIncomingUri(
    Uri uri, {
    required String? currentUserId,
  }) async {
    final flow = matchFlow(uri);
    if (flow == null) {
      return const AuthDeepLinkValidation.rejected('unrecognized_auth_uri');
    }

    final fragmentParams = uri.fragment.isNotEmpty
        ? Uri.splitQueryString(uri.fragment)
        : const <String, String>{};
    final hasImplicitToken = uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('refresh_token') ||
        fragmentParams.containsKey('access_token') ||
        fragmentParams.containsKey('refresh_token');
    if (hasImplicitToken) {
      return const AuthDeepLinkValidation.rejected('implicit_token_rejected');
    }

    final error = uri.queryParameters['error_description'] ??
        uri.queryParameters['error'] ??
        fragmentParams['error_description'] ??
        fragmentParams['error'];
    if (error != null && error.isNotEmpty) {
      return AuthDeepLinkValidation.rejected(error);
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      return const AuthDeepLinkValidation.rejected('missing_pkce_code');
    }

    final pending = await _readPendingFlow(flow);
    if (!pending.active) {
      return const AuthDeepLinkValidation.rejected('no_pending_auth_flow');
    }

    if (flow == AuthRedirectFlow.loginCallback &&
        currentUserId != null &&
        currentUserId != pending.initiatedUserId) {
      return const AuthDeepLinkValidation.rejected('active_session_conflict');
    }

    if (flow == AuthRedirectFlow.resetPassword &&
        currentUserId != null &&
        pending.initiatedUserId != null &&
        currentUserId != pending.initiatedUserId) {
      return const AuthDeepLinkValidation.rejected('active_session_conflict');
    }

    return AuthDeepLinkValidation.accepted(flow);
  }
}

