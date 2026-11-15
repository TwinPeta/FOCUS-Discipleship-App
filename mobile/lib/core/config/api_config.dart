/// Where the app finds the backend. The production API is the default; point a
/// build somewhere else (a staging server, your own machine) with:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1        (Android emulator -> your Mac)
///   flutter run --dart-define=API_BASE_URL=http://localhost:4000/v1       (iOS simulator)
///   flutter build apk --dart-define=API_BASE_URL=https://staging-api.focusuganda.org/v1
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://apis.focusuganda.org/v1',
  );
}
