import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/open_link.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import 'learning_providers.dart';
import 'widgets/viewer_parts.dart';

/// Screen 37: Document (`/document/:id`). The file opens in the phone's
/// own viewer (browser or a PDF app) from the link the server gives.
class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({super.key, required this.id, required this.origin});

  final String id;
  final LearningOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    return ref
        .watch(documentContentProvider(id))
        .when(
          loading: () =>
              Scaffold(backgroundColor: AppColors.page, body: const Skeleton()),
          error: (e, s) => ErrorScreen(
            onRetry: () => ref.invalidate(documentContentProvider(id)),
          ),
          data: (doc) {
            final details = [
              doc.format,
              doc.sizeLabel,
            ].where((s) => s.isNotEmpty).join(' · ');
            final url = doc.url;
            return ViewerScaffold(
              origin: origin,
              itemId: doc.item.id,
              chips: viewerChips('Document'),
              title: doc.item.title,
              headerBelowTitle: Text(details, style: AppTextStyles.bodyMedium),
              content: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 40,
                        color: AppColors.placeholder,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          url == null
                              ? 'This document is not available yet.'
                              : 'Opens in your phone\'s viewer, where you can '
                                    'also save it.',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Open document',
                  icon: Icons.open_in_new_rounded,
                  onPressed: url == null || !online
                      ? null
                      : () => openExternalLink(context, url),
                ),
              ],
              bottom: CompleteButton(
                label: 'Mark as done',
                item: doc.item,
                origin: origin,
              ),
            );
          },
        );
  }
}
