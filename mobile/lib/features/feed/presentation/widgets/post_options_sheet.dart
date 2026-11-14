import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/bottom_sheet_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/error_snack.dart';
import '../../../messaging/domain/report.dart';
import '../../../messaging/presentation/content_report_screens.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/post.dart';
import '../providers/feed_providers.dart';

/// Placeholder deep link until real links exist.
String postLink(String postId) => 'https://fcu.app/post/$postId';

/// "Post hidden" with an Undo that brings it back.
void showPostHiddenSnack(
  ScaffoldMessengerState messenger,
  PostActions actions,
  Post post,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Post hidden. You will not see it again.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => actions.unhide(post).catchError((_) {}),
        ),
      ),
    );
}

/// Screen 40: Post options. [onDetail] is true when opened from the post
/// screen, which then closes after Hide or Delete.
Future<void> showPostOptionsSheet(
  BuildContext context,
  Post post, {
  bool onDetail = false,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) =>
        _PostOptionsSheet(post: post, onDetail: onDetail, hostContext: context),
  );
}

class _PostOptionsSheet extends ConsumerWidget {
  const _PostOptionsSheet({
    required this.post,
    required this.onDetail,
    required this.hostContext,
  });

  final Post post;
  final bool onDetail;

  /// The screen under the sheet: every action closes the sheet first and
  /// then works from here.
  final BuildContext hostContext;

  void _leaveDetail(GoRouter router) {
    if (!onDetail) return;
    router.canPop() ? router.pop() : router.go(feedRouteFor(post));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentProfileProvider)?.id;
    final isAuthor = me != null && me == post.author.id;
    final actions = ref.read(postActionsProvider);
    final router = GoRouter.of(hostContext);
    final messenger = ScaffoldMessenger.of(hostContext);
    void close() => Navigator.of(context).pop();

    return BottomSheetScaffold(
      title: 'Post options',
      children: [
        if (!isAuthor)
          BottomSheetAction(
            icon: Icons.flag_outlined,
            label: 'Report post',
            onTap: () {
              close();
              router.push(
                contentReportLocation(
                  type: ReportTargetType.post,
                  id: post.id,
                  authorId: post.author.id,
                  authorName: post.author.name,
                  communityId: post.communityId,
                  preview: post.body,
                  back: feedRouteFor(post),
                ),
              );
            },
          ),
        BottomSheetAction(
          icon: Icons.visibility_off_outlined,
          label: 'Hide this post',
          onTap: () async {
            close();
            _leaveDetail(router);
            try {
              await actions.hide(post);
              showPostHiddenSnack(messenger, actions, post);
            } catch (_) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Could not hide this post.')),
              );
            }
          },
        ),
        BottomSheetAction(
          icon: Icons.link_rounded,
          label: 'Copy link',
          onTap: () async {
            close();
            await Clipboard.setData(ClipboardData(text: postLink(post.id)));
            messenger.showSnackBar(
              const SnackBar(content: Text('Link copied')),
            );
          },
        ),
        if (isAuthor)
          BottomSheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete post',
            destructive: true,
            onTap: () async {
              close();
              final confirmed = await showConfirmDialog(
                hostContext,
                title: 'Delete this post?',
                message:
                    'It will be removed for everyone, with its comments. '
                    'This cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              );
              if (!confirmed) return;
              try {
                await actions.delete(post, byUserId: me);
              } catch (_) {
                if (hostContext.mounted) {
                  showErrorSnack(hostContext, 'Could not delete this post.');
                }
                return;
              }
              _leaveDetail(router);
              messenger.showSnackBar(
                const SnackBar(content: Text('Post deleted')),
              );
            },
          ),
        BottomSheetAction(
          icon: Icons.close_rounded,
          label: 'Cancel',
          onTap: close,
        ),
      ],
    );
  }
}
