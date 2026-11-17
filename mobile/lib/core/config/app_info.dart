/// This build's version, e.g. `1.0.0-beta.2`. CI passes the `version:` from
/// pubspec.yaml (`--dart-define=APP_VERSION=...`); empty for local builds,
/// which never offer updates.
const appVersion = String.fromEnvironment('APP_VERSION');

/// How the version reads on Settings (46).
String get appVersionLabel =>
    appVersion.isEmpty ? 'Development build' : 'Version $appVersion';

/// Support contact (Help & FAQ, 50). Placeholder until the real mailbox is
/// confirmed; copied to the clipboard (no url_launcher without approval).
const supportEmail = 'support@fcu.example';
