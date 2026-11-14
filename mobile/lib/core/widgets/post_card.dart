import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
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
    this.onLikeTap,
    this.onCommentTap,
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
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;

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
              if (roleBadgeLabel != null) RoleBadge(label: roleBadgeLabel!),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: AppTextStyles.body.copyWith(height: 1.5)),
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
            Row(
              children: [
                _ActionButton(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: likeCount > 0 ? 'Like ($likeCount)' : 'Like',
                  highlighted: liked,
                  onTap: onLikeTap,
                ),
                const SizedBox(width: 18),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? Colors.red : AppColors.inkDeemphasized80;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
