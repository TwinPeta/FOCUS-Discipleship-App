import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'avatar_with_presence.dart';
import 'role_badge.dart';

/// A feed post card, shared by the general and specific-community feeds.
/// Posts with no [roleBadgeLabel] also have no action row, matching the
/// "plain member" seed post in the brief.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.authorName,
    required this.authorInitials,
    this.authorPhotoPath,
    required this.timestamp,
    required this.body,
    this.roleBadgeLabel,
    this.media = const [],
    this.showActions = true,
    this.liked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.onLikeTap,
    this.onCommentTap,
    this.photo,
    this.onOpen,
    this.onMore,
  });

  final String authorName;
  final String authorInitials;
  final String? authorPhotoPath;
  final String timestamp;
  final String body;
  final String? roleBadgeLabel;
  final List<String> media;
  final bool showActions;
  final bool liked;
  final int likeCount;
  final int commentCount;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;

  /// Shown 150px tall above the caption (radius 12).
  final Widget? photo;

  /// Tapping the caption or photo opens the post.
  final VoidCallback? onOpen;

  /// The 44px "..." button (post options).
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithPresence(
                initials: authorInitials,
                photoPath: authorPhotoPath,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timestamp,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.inkDeemphasized80,
                      ),
                    ),
                  ],
                ),
              ),
              if (roleBadgeLabel != null)
                Flexible(child: RoleBadge(label: roleBadgeLabel!)),
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  tooltip: 'Post options',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
          if (photo != null) ...[
            const SizedBox(height: 10),
            Semantics(
              button: onOpen != null,
              label: 'Photo. Open post',
              child: GestureDetector(
                onTap: onOpen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: photo,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Text(body, style: AppTextStyles.body.copyWith(height: 1.5)),
          ),
          if (media.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                width: double.infinity,
                color: AppColors.cream,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: AppColors.placeholder,
                ),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 0,
              children: [
                PostActionButton.like(
                  liked: liked,
                  count: likeCount,
                  onTap: onLikeTap,
                ),
                const SizedBox(width: 18),
                PostActionButton.comment(
                  count: commentCount,
                  onTap: onCommentTap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The 44px icon + count buttons under a post (like, comment). The row shows
/// only the icon and the number; screen readers get the words through
/// [semanticLabel] (for example "Like, 24 likes"). Inactive when [onTap] is
/// null.
class PostActionButton extends StatelessWidget {
  const PostActionButton({
    super.key,
    required this.icon,
    required this.count,
    required this.semanticLabel,
    this.onTap,
    this.highlighted = false,
    this.toggled,
  });

  /// The like control: a filled heart when [liked].
  PostActionButton.like({
    Key? key,
    required bool liked,
    required int count,
    VoidCallback? onTap,
  }) : this(
         key: key,
         icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
         count: count,
         semanticLabel: 'Like, ${countLabel(count, 'like')}',
         highlighted: liked,
         toggled: liked,
         onTap: onTap,
       );

  /// The comments control.
  const PostActionButton.comment({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) : this(
         key: key,
         icon: Icons.mode_comment_outlined,
         count: count,
         semanticLabel: 'Comments, $count',
         onTap: onTap,
       );

  final IconData icon;
  final int count;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool highlighted;

  /// Reported to screen readers as a toggle state when not null.
  final bool? toggled;

  /// "1 like", "24 likes".
  static String countLabel(int n, String noun) =>
      '$n $noun${n == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.error : AppColors.inkDeemphasized80;
    return Semantics(
      button: true,
      enabled: onTap != null,
      toggled: toggled,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
