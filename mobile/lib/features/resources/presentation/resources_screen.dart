import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/filter_chips.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../activity/domain/activity_event.dart';
import '../../activity/presentation/providers/activity_providers.dart';
import '../domain/resource.dart';
import 'providers/resource_providers.dart';

/// Screen 7: Resources tab inside [CommunityShell].
class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  ResourceType? _typeFilter;
  ResourceTopic? _topicFilter;

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

  Future<void> _openResource(Resource resource) async {
    if (resource.type == ResourceType.video) {
      await ref.read(activityRepositoryProvider).record(
        ActivityEvent(type: 'video_watched', label: 'Watched "${resource.title}"', at: DateTime.now()),
      );
      ref.invalidate(activityEventsProvider);
      ref.invalidate(badgesProvider);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${resource.title} coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider(widget.communityId));

    return resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Could not load resources.', style: AppTextStyles.body),
      ),
      data: (resources) {
        var filtered = resources;
        if (_typeFilter != null) {
          filtered = filtered.where((r) => r.type == _typeFilter).toList();
        }
        if (_topicFilter != null) {
          filtered = filtered.where((r) => r.topic == _topicFilter).toList();
        }

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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TopicTile(
                    icon: Icons.groups_rounded,
                    title: 'Bible characters',
                    subtitle: 'People of faith',
                    color: AppColors.amber,
                    selected: _topicFilter == ResourceTopic.characters,
                    onTap: () => setState(() {
                      _topicFilter = _topicFilter == ResourceTopic.characters
                          ? null
                          : ResourceTopic.characters;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopicTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Bible texts',
                    subtitle: 'Key passages',
                    color: AppColors.honey,
                    selected: _topicFilter == ResourceTopic.texts,
                    onTap: () => setState(() {
                      _topicFilter = _topicFilter == ResourceTopic.texts
                          ? null
                          : ResourceTopic.texts;
                    }),
                  ),
                ),
              ],
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
                    child: Icon(_typeIcon(filtered[i].type), color: AppColors.ink),
                  ),
                  title: filtered[i].title,
                  subtitle: '${_typeLabel(filtered[i].type)} · ${filtered[i].meta}',
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
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Start',
                                style: AppTextStyles.chip.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
                ),
                if (i != filtered.length - 1) const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: selected ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
