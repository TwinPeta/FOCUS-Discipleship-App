import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings saved on the device. `main` loads them before the first frame
/// and overrides this; tests and previews have none (nothing is saved).
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// The user's colour mode (Light / Dark / System), roadmap A0.3.
/// Read with `ref.watch(themeModeProvider)`, change with
/// `ref.read(themeModeProvider.notifier).set(mode)`. Remembered on the
/// device across restarts.
class ThemeModeController extends Notifier<ThemeMode> {
  static const storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider)?.getString(storageKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.light,
    );
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider)?.setString(storageKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
