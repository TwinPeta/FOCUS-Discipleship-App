/// Where the app finds the backend. Chosen at build time, never hard-coded:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1        (Android emulator -> your Mac)
///   flutter run --dart-define=API_BASE_URL=http://localhost:4000/v1       (iOS simulator)
///   flutter build apk --dart-define=API_BASE_URL=https://apis.focusuganda.org/v1
///
/// With no value the app runs on its built-in fake data (this is what the
/// tests and the offline demo use).
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get useRemote => baseUrl.isNotEmpty;
}
