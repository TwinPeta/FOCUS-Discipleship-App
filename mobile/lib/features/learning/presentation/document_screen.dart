import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import 'learning_providers.dart';
import 'widgets/viewer_parts.dart';

/// Screen 37: Document (`/document/:id`). The page is a placeholder until a
/// PDF viewer is approved; Download is a stub.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.id, required this.origin});

  final String id;
  final LearningOrigin origin;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(documentContentProvider(widget.id))
        .when(
          loading: () =>
              const Scaffold(backgroundColor: AppColors.page, body: Skeleton()),
          error: (e, s) => ErrorScreen(
            onRetry: () => ref.invalidate(documentContentProvider(widget.id)),
          ),
          data: (doc) => ViewerScaffold(
            origin: widget.origin,
            itemId: doc.item.id,
            chips: viewerChips('Document'),
            title: doc.item.title,
            headerBelowTitle: Text(
              '${doc.format} · ${doc.sizeLabel}',
              style: AppTextStyles.bodyMedium,
            ),
            content: [
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                  border: Border.all(color: AppColors.inputBorder, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Semantics(
                  label: 'Document page $_page of ${doc.pageCount}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppColors.placeholder,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Page $_page of ${doc.pageCount}',
                        style: AppTextStyles.cardTitle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: _page > 1 ? () => setState(() => _page--) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    '$_page / ${doc.pageCount}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: _page < doc.pageCount
                        ? () => setState(() => _page++)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              AppSecondaryButton(
                label: 'Download',
                icon: Icons.download_rounded,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloads are coming soon.')),
                ),
              ),
            ],
            bottom: CompleteButton(
              label: 'Mark as done',
              item: doc.item,
              origin: widget.origin,
            ),
          ),
        );
  }
}
