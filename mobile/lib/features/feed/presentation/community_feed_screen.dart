import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../profile/presentation/profile_providers.dart';
import '../domain/post.dart';
import 'widgets/compose_fab.dart';
import 'widgets/composer_row.dart';
import 'widgets/feed_list.dart';

/// The "Feed" tab inside [CommunityShell] for a specific community.
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    void compose() => context.push('/community/$communityId/compose');

    return Stack(
      children: [
        FeedList(
          feedKey: (communityId: communityId, scope: PostScope.specific),
          onCompose: compose,
          header: [
            ComposerRow(
              initials: profile?.initials ?? 'Y',
              photoPath: profile?.photoPath,
              onTap: compose,
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ComposeFab(onPressed: compose),
        ),
      ],
    );
  }
}
