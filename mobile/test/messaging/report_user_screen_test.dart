import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/features/messaging/presentation/report_user_screen.dart';

import '../support/pump_utils.dart';

void main() {
  testWidgets('Send report stays disabled until a reason is chosen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/x',
            routes: [
              GoRoute(
                path: '/x',
                builder: (context, state) =>
                    const ReportUserScreen(threadId: 'thread-sm-1'),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    final sendButtonFinder = find.widgetWithText(ElevatedButton, 'Send report');
    expect(tester.widget<ElevatedButton>(sendButtonFinder).onPressed, isNull);

    await tester.tap(find.text('Harassment or bullying'));
    await settle(tester);

    expect(tester.widget<ElevatedButton>(sendButtonFinder).onPressed, isNotNull);
  });
}
