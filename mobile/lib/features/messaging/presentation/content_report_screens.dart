import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/error_snack.dart';
import '../../feed/presentation/providers/feed_providers.dart';
import '../../feed/presentation/widgets/post_options_sheet.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/report.dart';
import 'report_flow.dart';

/// The route for reporting a piece of content (post, comment, prayer
/// request, testimony). [back] is where "Back to community" returns.
String contentReportLocation({
  required ReportTargetType type,
  required String id,
  String? authorId,
  String? authorName,
  required String communityId,
  required String preview,
  required String back,
}) {
  final excerpt = preview.length > _previewLength
      ? '${preview.substring(0, _previewLength).trimRight()}…'
      : preview;
  return Uri(
    path: '/report/${type.slug}/$id',
    queryParameters: {
      'user': ?authorId,
      'name': ?authorName,
      'community': communityId,
      'preview': excerpt,
      'back': back,
    },
  ).toString();
}

/// Longest content excerpt carried to the moderator.
const _previewLength = 160;

/// Screen 41: Report content (the [ReportFlow] for post, comment, prayer
/// request or testimony). Every report lands in the same repository.
class ContentReportScreen extends ConsumerWidget {
  const ContentReportScreen({
    super.key,
    required this.type,
    required this.id,
    this.authorId,
    this.authorName,
    this.communityId,
    this.preview,
    required this.back,
  });

  final ReportTargetType type;
  final String id;
  final String? authorId;
  final String? authorName;
  final String? communityId;
  final String? preview;
  final String back;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = authorName;
    return ReportFlow(
      title: 'Report this ${type.noun}',
      subtitle: name == null || name.isEmpty
          ? reportSubtitle('a ', type.noun)
          : reportSubtitle('a ${type.noun} by ', name),
      question: 'What is wrong?',
      onSubmit: (reason, details) async {
        final me = ref.read(currentProfileProvider);
        await ref
            .read(reportRepositoryProvider)
            .submitReport(
              Report(
                targetType: type,
                targetId: id,
                targetUserId: authorId,
                reason: reason,
                details: details,
                communityId: communityId,
                targetUserName: authorName,
                preview: preview,
                reporterId: me?.id,
                reporterName: me?.fullName,
              ),
            );
        if (!context.mounted) return;
        context.pushReplacement(
          Uri(
            path: '/report/${type.slug}/$id/sent',
            queryParameters: {'back': back},
          ).toString(),
        );
      },
    );
  }
}

/// Screen 42: Report sent (content). Posts also offer **Hide this post**.
class ContentReportSentScreen extends ConsumerStatefulWidget {
  const ContentReportSentScreen({
    super.key,
    required this.type,
    required this.id,
    required this.back,
  });

  final ReportTargetType type;
  final String id;
  final String back;

  @override
  ConsumerState<ContentReportSentScreen> createState() =>
      _ContentReportSentScreenState();
}

class _ContentReportSentScreenState
    extends ConsumerState<ContentReportSentScreen> {
  bool _hiding = false;

  Future<void> _hidePost() async {
    setState(() => _hiding = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(postActionsProvider);
    try {
      final post = await ref.read(postRepositoryProvider).getPost(widget.id);
      if (post != null) {
        await actions.hide(post);
        showPostHiddenSnack(messenger, actions, post);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hiding = false);
        showErrorSnack(context, 'Could not hide this post. Please try again.');
      }
      return;
    }
    router.go(widget.back);
  }

  @override
  Widget build(BuildContext context) {
    final isPost = widget.type == ReportTargetType.post;
    return ReportSentView(
      message:
          'Thank you for helping keep the community safe. A moderator will '
          'review it.',
      primaryLabel: 'Back to community',
      onPrimary: () => context.go(widget.back),
      secondaryLabel: isPost ? 'Hide this post' : null,
      secondaryLoading: _hiding,
      onSecondary: isPost ? _hidePost : null,
    );
  }
}
