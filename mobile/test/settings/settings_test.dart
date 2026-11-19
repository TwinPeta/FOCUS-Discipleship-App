import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/config/app_info.dart';
import 'package:focus_1/core/providers/repository_providers.dart';
import 'package:focus_1/core/theme/theme_mode_provider.dart';
import 'package:focus_1/features/auth/presentation/sign_in_screen.dart';
import 'package:focus_1/features/profile/presentation/edit_profile_screen.dart';
import 'package:focus_1/features/profile/presentation/profile_providers.dart';
import 'package:focus_1/features/settings/presentation/help_screen.dart';
import 'package:focus_1/features/settings/presentation/settings_screen.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

ElevatedButton _save(WidgetTester tester) => tester.widget<ElevatedButton>(
  find.widgetWithText(ElevatedButton, 'Save changes'),
);

void main() {
  testWidgets('46: rows, version, sign out confirms and goes to login', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings');

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      find.text('@${testProfile.username} · ${testProfile.institutionName}'),
      findsOneWidget,
    );
    expect(find.text('Edit profile'), findsNothing, reason: 'card opens it');
    for (final t in [
      'Appearance',
      'Light',
      'In-app and email',
      'English',
      'Download or delete my data',
      'Answers and contact',
      'App updates',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.ensureVisible(find.text(appVersionLabel));
    expect(find.text(appVersionLabel), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await settle(tester);
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await settle(tester, steps: 12);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('46: profile card opens Edit profile', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings');
    await tester.tap(find.text(testProfile.fullName));
    await settle(tester, steps: 12);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('46: Appearance: choosing Dark sets the theme mode', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings');
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text('Appearance'));
    await settle(tester);
    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(find.text('System'), findsNothing, reason: 'sheet closed');
    expect(find.text('Dark'), findsOneWidget, reason: 'row subtitle');
  });

  testWidgets('47: save disabled until changed and valid; saves the name', (
    tester,
  ) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/settings/profile');

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(
      find.text('Email: ${testProfile.email} · cannot be changed here.'),
      findsOneWidget,
    );
    expect(find.text('I study at'), findsOneWidget);
    expect(_save(tester).onPressed, isNull, reason: 'nothing changed');

    final name = find.widgetWithText(TextField, testProfile.fullName);
    await tester.enterText(name, '');
    await tester.pump();
    expect(_save(tester).onPressed, isNull, reason: 'invalid');

    await tester.enterText(find.byType(TextField).first, 'New Name');
    await tester.pump();
    expect(_save(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
    await settle(tester, steps: 12);
    expect(container.read(currentProfileProvider)!.fullName, 'New Name');
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('47: a taken username blocks saving', (tester) async {
    final container = await pumpFcuApp(tester);
    final repo = container.read(profileRepositoryProvider);
    await tester.runAsync(
      () => repo.createProfile(
        testProfile.copyWith(
          id: 'someone-else',
          username: 'takenname',
          email: 'else@fcu.test',
        ),
      ),
    );
    await goTo(tester, container, '/settings/profile');
    await tester.enterText(
      find.widgetWithText(TextField, testProfile.username),
      'takenname',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
    await settle(tester, steps: 12);
    expect(find.text('That username is already taken'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(
      container.read(currentProfileProvider)!.username,
      testProfile.username,
    );
  });

  testWidgets('/profile/edit folds into Edit profile', (tester) async {
    final container = await pumpFcuApp(tester);
    await goTo(tester, container, '/profile/edit');
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('50: first answer open; copy support email', (tester) async {
    final container = await pumpFcuApp(tester, signedIn: false);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await goTo(tester, container, '/help');

    expect(find.byType(HelpScreen), findsOneWidget, reason: 'public route');
    expect(find.text(helpFaq.first.$2), findsOneWidget);
    expect(find.text(helpFaq[1].$2), findsNothing, reason: 'collapsed');

    await tester.tap(find.text('Copy support email'));
    await settle(tester);
    expect(copied, supportEmail);
  });
}
