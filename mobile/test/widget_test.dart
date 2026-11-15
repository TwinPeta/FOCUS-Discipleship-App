import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/main.dart';

import 'support/fake_backend.dart';

void main() {
  testWidgets('App boots to the landing route', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: fakeBackend(), child: const FcuApp()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FcuApp), findsOneWidget);
  });
}
