import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_1/core/theme/app_colors.dart';
import 'package:focus_1/core/theme/theme_mode_provider.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('choosing Dark repaints the app in the dark palette', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/profile');
    final page = AppColors.page;

    app.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(AppColors.isDark, isTrue);
    expect(AppColors.page, isNot(page));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppPalette.dark.page);

    app.read(themeModeProvider.notifier).set(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(AppColors.isDark, isFalse);
  });

  test('the chosen theme is remembered across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    expect(first.read(themeModeProvider), ThemeMode.light);
    first.read(themeModeProvider.notifier).set(ThemeMode.dark);
    first.dispose();

    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(themeModeProvider), ThemeMode.dark);
  });
}
