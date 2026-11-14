import 'package:flutter_test/flutter_test.dart';

import 'package:focus_1/features/testimony/data/testimony_repository.dart';
import 'package:focus_1/features/testimony/domain/testimony.dart';

void main() {
  test('others never see a pending story, only reviewed ones', () async {
    final repo = FakeTestimonyRepository();
    final visible = await repo.getTestimonies('growth-circle');

    expect(visible, isNotEmpty);
    expect(visible.every((t) => t.status == TestimonyStatus.reviewed), isTrue);
  });

  test('the author sees their own pending story (drives the "awaiting review" banner)', () async {
    final repo = FakeTestimonyRepository();
    final mine = Testimony(
      id: 'mine-1',
      communityId: 'growth-circle',
      type: TestimonyType.story,
      title: 'My story',
      excerpt: 'Excerpt',
      authorName: 'Grace Namuli',
      institution: 'Makerere University',
      status: TestimonyStatus.pending,
      createdAt: DateTime.now(),
      isMine: true,
    );
    await repo.submitStory(mine);

    final visible = await repo.getTestimonies('growth-circle');
    final hasPendingMine =
        visible.any((t) => t.isMine && t.status == TestimonyStatus.pending);

    expect(hasPendingMine, isTrue);
  });
}
