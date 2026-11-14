import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../data/learning_repository.dart';
import '../domain/learning_models.dart';
import 'learning_providers.dart';
import 'widgets/viewer_parts.dart';

/// Screen 34: Devotional (`/devotional/:id`) with a private reflection.
class DevotionalScreen extends ConsumerWidget {
  const DevotionalScreen({super.key, required this.id, required this.origin});

  final String id;
  final LearningOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(devotionalContentProvider(id))
        .when(
          loading: () =>
              const Scaffold(backgroundColor: AppColors.page, body: Skeleton()),
          error: (e, s) => ErrorScreen(
            onRetry: () => ref.invalidate(devotionalContentProvider(id)),
          ),
          data: (d) => _DevotionalView(content: d, origin: origin),
        );
  }
}

class _DevotionalView extends ConsumerStatefulWidget {
  const _DevotionalView({required this.content, required this.origin});

  final DevotionalContent content;
  final LearningOrigin origin;

  @override
  ConsumerState<_DevotionalView> createState() => _DevotionalViewState();
}

class _DevotionalViewState extends ConsumerState<_DevotionalView> {
  final _reflection = TextEditingController();
  late final LearningRepository _repo = ref.read(learningRepositoryProvider);
  Timer? _debounce;
  String _saved = '';

  String get _id => widget.content.item.id;

  @override
  void initState() {
    super.initState();
    _repo.getReflection(_id).then((r) {
      if (!mounted || r == null) return;
      _saved = r.text;
      _reflection.text = r.text;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Flush the latest text (no ref use after dispose).
    if (_reflection.text != _saved) {
      _repo.saveReflection(_id, _reflection.text).ignore();
    }
    _reflection.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final text = _reflection.text;
    if (text == _saved) return;
    await _repo.saveReflection(_id, text);
    _saved = text;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.content;
    return ViewerScaffold(
      origin: widget.origin,
      itemId: d.item.id,
      chips: viewerChips(
        'Devotional',
        topic: d.reference,
        extra: '${d.readMinutes} min read',
      ),
      title: d.item.title,
      content: [
        for (final p in d.paragraphs) ...[
          Text(
            p,
            style: AppTextStyles.body.copyWith(fontSize: 17, height: 1.55),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To think about', style: AppTextStyles.cardTitle),
              const SizedBox(height: 6),
              Text(d.thinkAbout, style: AppTextStyles.body),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTextArea(
          label: 'Your reflection',
          controller: _reflection,
          placeholder: 'Write your thoughts (only you see this)',
          minHeight: 120,
          onChanged: _onChanged,
        ),
      ],
      bottom: CompleteButton(
        label: 'Mark as read',
        item: d.item,
        origin: widget.origin,
        beforeComplete: _save,
      ),
    );
  }
}
