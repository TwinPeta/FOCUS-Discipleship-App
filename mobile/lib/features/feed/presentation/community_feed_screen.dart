import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../community/presentation/providers/community_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/post.dart';
import 'widgets/composer_row.dart';
import 'widgets/feed_list.dart';
import 'widgets/next_meeting_card.dart';

/// Screen 5: the "Feed" section of a specific community (in
/// [CommunityShell]): what to share, the next meeting, then posts,
/// questions and announcements. Creating goes through the Create screen
/// (the row here, or the bottom bar's +).
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final community = ref.watch(communityByIdProvider(communityId)).valueOrNull;

    return FeedList(
      feedKey: (communityId: communityId, scope: PostScope.specific),
      onCompose: () => context.push('/create?type=post&to=$communityId'),
      header: [
        ComposerRow(
          initials: profile?.initials ?? 'Y',
          photoPath: profile?.photoPath,
          target: communityId,
        ),
        if (community != null && community.meetingDay != null)
          NextMeetingCard(community: community),
      ],
    );
  }
}
