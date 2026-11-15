import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/testimony/domain/testimony.dart';

import '../support/fakes.dart';

Testimony _story({
  String id = 'mine-1',
  TestimonyStatus status = TestimonyStatus.pending,
}) => Testimony(
  id: id,
  communityId: 'growth-circle',
  type: TestimonyType.story,
  title: 'My story',
  excerpt: 'Excerpt',
  authorId: 'author-1',
  authorName: 'Grace Namuli',
  institution: 'Makerere University',
  status: status,
  createdAt: DateTime.now(),
);

void main() {
  FakeTestimonyRepository repo() =>
      FakeTestimonyRepository(latency: Duration.zero);

  test('others never see a pending story, only reviewed ones', () async {
    final r = repo();
    await r.submitStory(_story());
    final visible = await r.getTestimonies(
      'growth-circle',
      viewerId: 'someone-else',
    );

    expect(visible, isNotEmpty);
    expect(visible.every((t) => t.status == TestimonyStatus.reviewed), isTrue);
  });

  test('a signed-out viewer never sees pending stories', () async {
    final r = repo();
    await r.submitStory(_story());
    final visible = await r.getTestimonies('growth-circle', viewerId: null);
    expect(visible.any((t) => t.status == TestimonyStatus.pending), isFalse);
  });

  test('the author sees their own pending story (drives the "awaiting review" banner)', () async {
    final r = repo();
    await r.submitStory(_story());

    final visible = await r.getTestimonies(
      'growth-circle',
      viewerId: 'author-1',
    );
    expect(
      visible.any(
        (t) =>
            t.isAuthoredBy('author-1') && t.status == TestimonyStatus.pending,
      ),
      isTrue,
    );
  });

  test(
    'a new story is stored as pending even if submitted as reviewed',
    () async {
      final r = repo();
      final stored = await r.submitStory(
        _story(id: 'sneaky', status: TestimonyStatus.reviewed),
      );
      expect(stored.status, TestimonyStatus.pending);
      final others = await r.getTestimonies('growth-circle', viewerId: 'x');
      expect(others.any((t) => t.id == 'sneaky'), isFalse);
    },
  );
}
