import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/sized_file_image.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/post.dart';
import 'providers/feed_providers.dart';

enum _MediaKind { photo, video, document }

class _PickedMedia {
  const _PickedMedia({required this.kind, required this.path, this.name});

  final _MediaKind kind;
  final String path;
  final String? name;
}

const _emojiOptions = [
  '😀',
  '😂',
  '🙏',
  '❤️',
  '🔥',
  '🎉',
  '👏',
  '🙌',
  '😊',
  '😍',
  '🤝',
  '✨',
  '👍',
  '😢',
  '🙇',
  '💯',
];

/// Screen 13: the post composer, reached from both feeds via
/// `/community/:id/compose` (specific) or `/general-feed/compose` (general;
/// the community id is resolved from the profile's institution).
class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key, this.communityId, required this.scope})
    : assert(scope == PostScope.general || communityId != null);

  /// Required for [PostScope.specific]; ignored for the General feed.
  final String? communityId;
  final PostScope scope;

  /// Photos/videos/documents per post.
  static const maxAttachments = 4;

  /// Picked photos are resized and recompressed before they are attached.
  static const photoMaxDimension = 1600.0;
  static const photoQuality = 80;

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final List<_PickedMedia> _media = [];
  bool _emojiPanelOpen = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _textController.text.trim().isNotEmpty || _media.isNotEmpty;

  bool get _isOnline => ref.read(isOnlineProvider).valueOrNull ?? true;

  /// Posting is paused while offline (see [OfflineBanner]).
  bool get _canPost => !_isPosting && _hasContent && _isOnline;

  _PickedMedia? get _firstPhoto =>
      _media.where((m) => m.kind == _MediaKind.photo).firstOrNull;

  bool get _canAttach => _media.length < ComposerScreen.maxAttachments;

  FeedKey? _feedKey() {
    if (widget.scope == PostScope.specific) {
      return (communityId: widget.communityId!, scope: PostScope.specific);
    }
    final general = ref.read(generalCommunityProvider).valueOrNull;
    if (general == null) return null;
    return (communityId: general.id, scope: PostScope.general);
  }

  bool _checkAttachLimit() {
    if (_canAttach) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You can attach up to ${ComposerScreen.maxAttachments} files.',
        ),
      ),
    );
    return false;
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Discard this post?', style: AppTextStyles.sectionHeading),
              const SizedBox(height: 6),
              Text(
                'Your text and attachments will be lost.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Discard',
                height: 48,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 10),
              AppSecondaryButton(
                label: 'Keep editing',
                height: 48,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    return discard ?? false;
  }

  Future<void> _close() async {
    if (_hasContent && !await _confirmDiscard()) return;
    if (!mounted) return;
    _discarded = true;
    setState(() {});
    context.pop();
  }

  bool _discarded = false;

  Future<void> _pickPhoto() async {
    if (!_checkAttachLimit()) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: ComposerScreen.photoMaxDimension,
      maxHeight: ComposerScreen.photoMaxDimension,
      imageQuality: ComposerScreen.photoQuality,
    );
    if (picked == null || !mounted || !_canAttach) return;
    setState(() {
      _media.add(_PickedMedia(kind: _MediaKind.photo, path: picked.path));
      _emojiPanelOpen = false;
    });
  }

  Future<void> _pickVideo() async {
    if (!_checkAttachLimit()) return;
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted || !_canAttach) return;
    setState(() {
      _media.add(_PickedMedia(kind: _MediaKind.video, path: picked.path));
      _emojiPanelOpen = false;
    });
  }

  Future<void> _pickDocument() async {
    if (!_checkAttachLimit()) return;
    final result = await FilePicker.platform.pickFiles();
    final files = result?.files ?? const [];
    if (files.isEmpty || !mounted || !_canAttach) return;
    final file = files.first;
    if (file.path == null) return;
    setState(() {
      _media.add(
        _PickedMedia(
          kind: _MediaKind.document,
          path: file.path!,
          name: file.name,
        ),
      );
      _emojiPanelOpen = false;
    });
  }

  void _toggleEmojiPanel() {
    setState(() => _emojiPanelOpen = !_emojiPanelOpen);
  }

  void _insertEmoji(String emoji) {
    final selection = _textController.selection;
    final text = _textController.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() {});
  }

  void _removeMedia(int index) {
    setState(() => _media.removeAt(index));
  }

  String get _mediaCountLabel {
    if (_media.isEmpty) return '';
    final counts = <_MediaKind, int>{};
    for (final item in _media) {
      counts[item.kind] = (counts[item.kind] ?? 0) + 1;
    }
    String label(_MediaKind kind) => switch (kind) {
      _MediaKind.photo => 'photo',
      _MediaKind.video => 'video',
      _MediaKind.document => 'document',
    };
    return counts.entries
        .map((e) => '${e.value} ${label(e.key)}${e.value == 1 ? '' : 's'}')
        .join(', ');
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    final profile = ref.read(currentProfileProvider);
    final key = _feedKey();
    if (profile == null || key == null) return;

    setState(() => _isPosting = true);
    final post = Post(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}',
      communityId: key.communityId,
      scope: key.scope,
      author: Person(
        id: profile.id,
        name: profile.fullName,
        role: PersonRole.member,
      ),
      body: _textController.text.trim(),
      createdAt: DateTime.now(),
      photo: _firstPhoto == null ? null : PostPhoto.file(_firstPhoto!.path),
      media: [
        for (final m in _media)
          if (!identical(m, _firstPhoto)) m.path,
      ],
    );

    try {
      await ref.read(feedPostsProvider(key).notifier).createPost(post);
    } catch (_) {
      if (mounted) {
        setState(() => _isPosting = false);
        showErrorSnack(context, 'Your post was not sent. Please try again.');
      }
      return;
    }

    if (!mounted) return;
    _discarded = true;
    setState(() {});
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    ref.watch(isOnlineProvider); // rebuild the Post button on change
    final String communityName;
    if (widget.scope == PostScope.general) {
      // Keeps the General community resolved for [_feedKey].
      ref.watch(generalCommunityProvider);
      communityName = 'General community';
    } else {
      communityName =
          ref
              .watch(communityByIdProvider(widget.communityId!))
              .valueOrNull
              ?.name ??
          '…';
    }

    return PopScope(
      canPop: !_hasContent || _discarded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _close,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                    Expanded(
                      child: Text(
                        'New post',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionHeading,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: ElevatedButton(
                        onPressed: _canPost ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          disabledBackgroundColor: AppColors.amber.withValues(
                            alpha: 0.4,
                          ),
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.button,
                            ),
                          ),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ink,
                                ),
                              )
                            : const Text(
                                'Post',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // The author row scrolls with the text, so the field keeps
                // its room when the keyboard is up.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InitialsAvatar(
                            initials: profile?.initials ?? 'Y',
                            photoPath: profile?.photoPath,
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile?.fullName ?? '',
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AppChip(
                                  label: 'Posting in $communityName',
                                  backgroundColor: AppColors.honey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        autofocus: true,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 20, height: 1.35),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(
                            fontSize: 20,
                            height: 1.35,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ),
                      if (_media.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 170,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _media.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) => _MediaPreview(
                              media: _media[index],
                              onRemove: () => _removeMedia(index),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_emojiPanelOpen)
                Container(
                  height: 178,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    border: Border(
                      top: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  child: GridView.count(
                    crossAxisCount: 7,
                    children: [
                      for (final emoji in _emojiOptions)
                        InkWell(
                          onTap: () => _insertEmoji(emoji),
                          borderRadius: BorderRadius.circular(8),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cream)),
                ),
                child: Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.image_outlined,
                      semanticLabel: 'Photo',
                      onPressed: _pickPhoto,
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.videocam_outlined,
                      semanticLabel: 'Video',
                      onPressed: _pickVideo,
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.attach_file_outlined,
                      semanticLabel: 'Document',
                      onPressed: _pickDocument,
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.emoji_emotions_outlined,
                      semanticLabel: 'Emoji',
                      active: _emojiPanelOpen,
                      onPressed: _toggleEmojiPanel,
                    ),
                    const SizedBox(width: 10),
                    if (_media.isNotEmpty)
                      Expanded(
                        child: Text(
                          _mediaCountLabel,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.fieldLabel.copyWith(
                            color: AppColors.inkDeemphasized80,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.amber : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.ink : AppColors.inputBorder,
              width: active ? 2 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.media, required this.onRemove});

  final _PickedMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 170,
            height: 170,
            color: AppColors.cream,
            alignment: Alignment.center,
            child: switch (media.kind) {
              _MediaKind.photo => Image(
                image: sizedFileImage(context, media.path, logicalSize: 170),
                width: 170,
                height: 170,
                fit: BoxFit.cover,
              ),
              _MediaKind.video => const Icon(
                Icons.play_circle_outline_rounded,
                size: 40,
                color: AppColors.placeholder,
              ),
              _MediaKind.document => Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 32,
                      color: AppColors.placeholder,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      media.name ?? 'Document',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.fieldLabel,
                    ),
                  ],
                ),
              ),
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Semantics(
            button: true,
            label: 'Remove attachment',
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 18, color: AppColors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
