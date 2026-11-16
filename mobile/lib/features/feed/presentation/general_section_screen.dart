import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/general_shell.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../prayer/presentation/prayer_wall_screen.dart';
import '../../testimony/presentation/testimonies_screen.dart';

/// A section of the General community other than its feed.
enum GeneralSection {
  prayer('Prayer wall', 'general/prayer'),
  testimonies('Testimonies', 'general/testimonies');

  const GeneralSection(this.label, this.menuPath);

  final String label;

  /// Its key in the "⋯" menu.
  final String menuPath;
}

/// `/general-feed/prayer` and `/general-feed/testimonies`: the campus-wide
/// Prayer wall and Testimonies, in the General header.
class GeneralSectionScreen extends ConsumerWidget {
  const GeneralSectionScreen({super.key, required this.section});

  final GeneralSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final general = ref.watch(generalCommunityProvider);
    return general.when(
      loading: () =>
          Scaffold(backgroundColor: AppColors.page, body: const Skeleton()),
      error: (_, _) =>
          ErrorScreen(onRetry: () => ref.invalidate(generalCommunityProvider)),
      data: (community) => GeneralShell(
        sectionLabel: section.label,
        activePath: section.menuPath,
        body: switch (section) {
          GeneralSection.prayer => PrayerWallScreen(
            communityId: community.id,
            createTarget: 'general',
            backRoute: '/general-feed/prayer',
          ),
          GeneralSection.testimonies => TestimoniesScreen(
            communityId: community.id,
            createTarget: 'general',
          ),
        },
      ),
    );
  }
}
