import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/general_shell.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import 'resources_screen.dart';

/// "Learn" (`/general-feed/resources`): the General community's resources,
/// open to everyone on campus, in the General header (name, section,
/// Search and the "⋯" sections menu).
class GeneralResourcesScreen extends ConsumerWidget {
  const GeneralResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(generalCommunityProvider);
    return GeneralShell(
      sectionLabel: 'Learn',
      activePath: 'general/resources',
      body: communityAsync.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 3),
        error: (error, stackTrace) =>
            ErrorView(onRetry: () => ref.invalidate(generalCommunityProvider)),
        data: (community) =>
            ResourcesScreen(communityId: community.id, inCommunityShell: false),
      ),
    );
  }
}
