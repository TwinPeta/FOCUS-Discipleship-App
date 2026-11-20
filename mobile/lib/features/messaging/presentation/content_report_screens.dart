import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/error_snack.dart';
import '../../community/domain/person.dart';
import '../../feed/presentation/providers/feed_providers.dart';
import '../../feed/presentation/widgets/post_options_sheet.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/report.dart';
import 'report_flow.dart';
import 'widgets/block_person.dart';

/// The route for reporting a member or a piece of content (post, comment,
/// prayer request, testimony). Content passes its [communityId] and a
/// [preview] for the moderation queue. [back] is where the sent screen
/// returns.
String contentReportLocation({
  required ReportTargetType type,
  required String id,
  String? authorId,
  String? authorName,
  String? communityId,
  String? preview,
  required String back,
}) {
  final excerpt = preview != null && preview.length > _previewLength
      ? '${preview.substring(0, _previewLength).trimRight()}…'
      : preview;
  return Uri(
    path: '/report/${type.slug}/$id',
    queryParameters: {
      'user': ?authorId,
      'name': ?authorName,
      'community': ?communityId,
      'preview': ?excerpt,
      'back': back,
    },
  ).toString();
}

/// Longest content excerpt carried to the moderator.
const _previewLength = 160;

/// Screen 41: Report content (the [ReportFlow] for post, comment, prayer
/// request or testimony), and the user report from a member profile (43).
/// Every report lands in the same repository.
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
    final isUser = type == ReportTargetType.user;
    final Widget subtitle;
    if (isUser) {
      subtitle = reportSubtitle('', name ?? 'this member');
    } else if (name == null || name.isEmpty) {
      subtitle = reportSubtitle('a ', type.noun);
    } else {
      subtitle = reportSubtitle('a ${type.noun} by ', name);
    }
    return ReportFlow(
      backFallback: back,
      title: isUser ? 'Report a user' : 'Report this ${type.noun}',
      subtitle: subtitle,
      question: isUser ? 'What happened?' : 'What is wrong?',
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
            queryParameters: {'back': back, 'name': ?authorName},
          ).toString(),
        );
      },
    );
  }
}

/// Screen 42: Report sent (content). Posts also offer **Hide this post**;
/// a user report offers **Block this user**.
class ContentReportSentScreen extends ConsumerStatefulWidget {
  const ContentReportSentScreen({
    super.key,
    required this.type,
    required this.id,
    required this.back,
    this.name,
  });

  final ReportTargetType type;
  final String id;
  final String back;

  /// The reported person's name (user reports).
  final String? name;

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

  Future<void> _blockUser() async {
    final router = GoRouter.of(context);
    final person = Person(
      id: widget.id,
      name: widget.name ?? 'this member',
      role: PersonRole.member,
    );
    if (await confirmAndBlock(context, ref, person)) router.go(widget.back);
  }

  @override
  Widget build(BuildContext context) {
    final isPost = widget.type == ReportTargetType.post;
    final isUser = widget.type == ReportTargetType.user;
    String? secondaryLabel;
    VoidCallback? onSecondary;
    if (isPost) {
      secondaryLabel = 'Hide this post';
      onSecondary = _hidePost;
    } else if (isUser) {
      secondaryLabel = 'Block this user';
      onSecondary = _blockUser;
    }
    return ReportSentView(
      message:
          'Thank you for helping keep the caregroup safe. A moderator will '
          'review it.',
      primaryLabel: isUser ? 'Back to profile' : 'Back to caregroup',
      onPrimary: () => context.go(widget.back),
      secondaryLabel: secondaryLabel,
      secondaryLoading: _hiding,
      onSecondary: onSecondary,
    );
  }
}
