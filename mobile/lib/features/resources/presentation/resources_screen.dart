import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/list_row_card.dart';
import '../domain/resource.dart';
import 'providers/resource_providers.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 7: Resources tab inside [CommunityShell], also the body of the
/// General community's "Learn" screen ([GeneralResourcesScreen]).
class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({
    super.key,
    required this.communityId,
    this.inCommunityShell = true,
  });

  final String communityId;

  /// When true, viewers opened from here fall back to this community's
  /// Resources tab on Back (deep link). The General community has no tab, so
  /// its Learn screen passes false.
  final bool inCommunityShell;

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  ResourceType? _typeFilter;

  String _typeLabel(ResourceType type) => switch (type) {
    ResourceType.video => 'VIDEO',
    ResourceType.devotional => 'DEVOTIONAL',
    ResourceType.quiz => 'QUIZ',
    ResourceType.document => 'DOCUMENT',
  };

  IconData _typeIcon(ResourceType type) => switch (type) {
    ResourceType.video => Icons.play_circle_outline_rounded,
    ResourceType.devotional => Icons.menu_book_outlined,
    ResourceType.quiz => Icons.quiz_outlined,
    ResourceType.document => Icons.description_outlined,
  };

  Color _tileColor(ResourceType type) => switch (type) {
    ResourceType.video || ResourceType.quiz => AppColors.honey,
    ResourceType.devotional || ResourceType.document => AppColors.cream,
  };

  void _openResource(Resource resource) {
    // Completion (and its activity) is recorded by the viewer itself.
    context.push(
      resourceRoute(
        resource,
        communityId: widget.inCommunityShell ? widget.communityId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider(widget.communityId));

    return resourcesAsync.when(
      loading: () => const Skeleton(showHeader: false, cardCount: 3),
      error: (error, stackTrace) => ErrorView(
        onRetry: () => ref.invalidate(resourcesProvider(widget.communityId)),
      ),
      data: (resources) {
        final filtered = filterResources(resources, type: _typeFilter);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            FilterChips<ResourceType?>(
              options: const [
                FilterChipOption(label: 'All', value: null),
                FilterChipOption(label: 'Videos', value: ResourceType.video),
                FilterChipOption(
                  label: 'Devotionals',
                  value: ResourceType.devotional,
                ),
                FilterChipOption(label: 'Quizzes', value: ResourceType.quiz),
                FilterChipOption(
                  label: 'Documents',
                  value: ResourceType.document,
                ),
              ],
              value: _typeFilter,
              onChanged: (value) => setState(() => _typeFilter = value),
            ),
            const SizedBox(height: 20),
            Text(
              'Latest',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No resources match these filters.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++) ...[
                ListRowCard(
                  leading: Container(
                    decoration: BoxDecoration(
                      color: _tileColor(filtered[i].type),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _typeIcon(filtered[i].type),
                      color: AppColors.ink,
                    ),
                  ),
                  title: filtered[i].title,
                  subtitle:
                      '${_typeLabel(filtered[i].type)} · ${filtered[i].meta}',
                  onTap: filtered[i].type == ResourceType.quiz
                      ? null
                      : () => _openResource(filtered[i]),
                  trailing: filtered[i].type == ResourceType.quiz
                      ? Semantics(
                          button: true,
                          label: 'Start ${filtered[i].title}',
                          child: InkWell(
                            onTap: () => _openResource(filtered[i]),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Start',
                                style: AppTextStyles.chip.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Icon(Icons.chevron_right_rounded, color: AppColors.ink),
                ),
                if (i != filtered.length - 1) const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}
