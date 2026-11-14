import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_colors.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/core/widgets/message_input_bar.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('typed text is ink, not white ($brightness phone)', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                const TextField(),
                MessageInputBar(
                  controller: controller,
                  onSend: () {},
                  hintText: 'Write a message',
                  sendLabel: 'Send',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.enterText(find.byType(TextField).last, 'Hi there');
      await tester.pump();

      for (final e in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(e.style.color, AppColors.ink, reason: 'input text colour');
      }
    });
  }
}
