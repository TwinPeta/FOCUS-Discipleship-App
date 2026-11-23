import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What is kept between launches so a student signs in once: the token pair,
/// and who it belongs to (so the app can open offline).
class SavedSession {
  const SavedSession({
    required this.access,
    required this.refresh,
    this.accountId,
    this.email,
  });

  final String access;
  final String refresh;
  final String? accountId;
  final String? email;
}

/// Where the session lives on the phone.
abstract class TokenVault {
  Future<SavedSession?> read();

  Future<void> write(SavedSession session);

  Future<void> clear();
}

/// The Keychain (iPhone) / encrypted storage (Android). The refresh token is
/// a long-lived credential, so it never goes in plain preferences.
class SecureTokenVault implements TokenVault {
  SecureTokenVault([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _access = 'fcu.access';
  static const _refresh = 'fcu.refresh';
  static const _account = 'fcu.account';
  static const _email = 'fcu.email';

  /// The four values are read at the same time (each read is a separate
  /// trip to the Keystore / Keychain).
  @override
  Future<SavedSession?> read() async {
    final values = await Future.wait([
      for (final key in [_access, _refresh, _account, _email])
        _storage.read(key: key),
    ]);
    final [access, refresh, account, email] = values;
    if (access == null || refresh == null) return null;
    return SavedSession(
      access: access,
      refresh: refresh,
      accountId: account,
      email: email,
    );
  }

  @override
  Future<void> write(SavedSession s) async {
    await Future.wait([
      _storage.write(key: _access, value: s.access),
      _storage.write(key: _refresh, value: s.refresh),
      if (s.accountId != null) _storage.write(key: _account, value: s.accountId),
      if (s.email != null) _storage.write(key: _email, value: s.email),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      for (final key in [_access, _refresh, _account, _email])
        _storage.delete(key: key),
    ]);
  }
}

/// For tests and when storage is unavailable: nothing survives a restart.
class MemoryTokenVault implements TokenVault {
  SavedSession? saved;

  @override
  Future<SavedSession?> read() async => saved;

  @override
  Future<void> write(SavedSession session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}
