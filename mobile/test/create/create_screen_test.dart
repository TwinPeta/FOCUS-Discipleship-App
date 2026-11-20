import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/router/app_router.dart';
import 'package:focus_1/features/community/domain/membership.dart';
import 'package:focus_1/features/community/presentation/providers/community_providers.dart';
import 'package:focus_1/features/feed/domain/post.dart';
import 'package:focus_1/features/feed/presentation/providers/feed_providers.dart';
import 'package:focus_1/features/prayer/presentation/providers/prayer_providers.dart';

import '../support/app_harness.dart';
import '../support/pump_utils.dart';

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.pump();
}

Future<void> _send(WidgetTester tester, String action) async {
  await tester.tap(find.bySemanticsLabel(action));
  await settle(tester, steps: 14);
}

void main() {
  testWidgets('an anonymous question to General', (tester) async {
    final semantics = tester.ensureSemantics();
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/create?type=question&to=general');

    expect(find.text('Tips for a good question'), findsOneWidget);
    expect(find.text('Add a photo (optional)'), findsNothing);
    await _type(tester, 'How do you keep a quiet time?');
    await tester.tap(find.text('Ask anonymously'));
    await tester.pump();
    expect(
      find.textContaining('Moderators can still see who posted'),
      findsOneWidget,
    );
    expect(find.text('Anonymous'), findsOneWidget);

    await _send(tester, 'Ask');
    expect(app.read(routerProvider).state.uri.path, '/general-feed');
    final general = await app.read(generalCommunityProvider.future);
    final posts = await app.read(
      feedPostsProvider((communityId: general.id, scope: PostScope.general))
          .future,
    );
    final q = posts.firstWhere(
      (p) => p.body == 'How do you keep a quiet time?',
    );
    expect(q.kind, PostKind.question);
    expect(q.anonymous, isTrue);
    semantics.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a prayer request to General lands on the General prayer wall', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/create?type=prayer&to=general');
    await _type(tester, 'Pray for my exams');
    await _send(tester, 'Share');
    expect(app.read(routerProvider).state.uri.path, '/general-feed/prayer');
    final general = await app.read(generalCommunityProvider.future);
    final wall = await app.read(prayerRequestsProvider(general.id).future);
    expect(wall.any((r) => r.body == 'Pray for my exams'), isTrue);
    semantics.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a story needs a title and consent, and cannot be anonymous', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final app = await pumpFcuApp(tester);
    await goTo(tester, app, '/create?type=story&to=growth-circle');
    expect(find.text('Post anonymously'), findsNothing);
    expect(
      find.textContaining('Moderators review every story'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'A new start');
    await _type(tester, 'God carried me through first year.');
    // No consent yet: Submit does nothing.
    await _send(tester, 'Submit');
    expect(app.read(routerProvider).state.uri.path, '/create');
    await tester.tap(find.textContaining('I agree to share my story'));
    await tester.pump();
    await _send(tester, 'Submit');
    expect(
      app.read(routerProvider).state.uri.path,
      '/community/growth-circle/testimonies',
    );
    semantics.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('"⋯" switches the type; without a caregroup only General', (
    tester,
  ) async {
    final app = await pumpFcuApp(tester, membership: MembershipStatus.none);
    await goTo(tester, app, '/create?type=post');
    expect(find.text('Add a photo (optional)'), findsOneWidget);
    expect(find.textContaining('Join a specific caregroup'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await settle(tester);
    await tester.tap(find.text('Prayer request').last);
    await settle(tester);
    expect(find.text('Add a photo (optional)'), findsNothing);
    expect(find.text('Post anonymously'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
