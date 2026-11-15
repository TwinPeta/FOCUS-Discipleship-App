import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/widgets/post_card.dart';

Widget _card({bool liked = false, int likes = 24, int comments = 6}) =>
    MaterialApp(
      home: Scaffold(
        body: PostCard(
          authorName: 'Grace Namuli',
          authorInitials: 'GN',
          timestamp: '2h',
          body: 'Hello campus',
          liked: liked,
          likeCount: likes,
          commentCount: comments,
          onLikeTap: () {},
          onCommentTap: () {},
        ),
      ),
    );

void main() {
  testWidgets('the action row shows icons and counts only, no words', (
    tester,
  ) async {
    await tester.pumpWidget(_card());

    expect(find.text('24'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(
      find.textContaining(RegExp('like', caseSensitive: false)),
      findsNothing,
    );
    expect(
      find.textContaining(RegExp('comment', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mode_comment_outlined), findsOneWidget);
  });

  testWidgets('screen readers still get the words', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(likes: 1));

    expect(find.bySemanticsLabel('Like, 1 like'), findsOneWidget);
    expect(find.bySemanticsLabel('Comments, 6'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a liked post keeps the filled heart and reports toggled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(liked: true, likes: 25));

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Like, 25 likes')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: true),
    );
    handle.dispose();
  });
}
