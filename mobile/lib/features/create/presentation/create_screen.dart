import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/router/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bottom_nav.dart' show approvedCommunityId;
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/check_row.dart';
import '../../../core/widgets/community_header_chrome.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/sized_file_image.dart';
import '../../../core/widgets/switch_row.dart';
import '../../community/domain/membership.dart';
import '../../community/domain/person.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../community/presentation/providers/membership_provider.dart';
import '../../feed/domain/post.dart';
import '../../feed/presentation/providers/feed_providers.dart';
import '../../prayer/domain/prayer_request.dart';
import '../../prayer/presentation/providers/prayer_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../testimony/domain/testimony.dart';
import '../../testimony/presentation/providers/testimony_providers.dart';
import '../../../core/media/video_picker.dart';
import '../../testimony/data/testimony_repository.dart';

/// What can be created from the + button (screen 66 and the Create screens).
enum CreateType {
  post('Post', Icons.edit_note_rounded, 'Post'),
  question('Question', Icons.help_outline_rounded, 'Ask'),
  prayer('Prayer request', Icons.volunteer_activism_outlined, 'Share'),
  story('Story', Icons.auto_stories_outlined, 'Submit');

  const CreateType(this.label, this.icon, this.action);

  final String label;
  final IconData icon;

  /// The button that sends it.
  final String action;

  /// Name hidden from students (moderators still see who). Stories keep
  /// the name: they are testimonies, published with their author.
  bool get canBeAnonymous => this != story;

  /// A photo with posts and stories.
  bool get canHavePhoto => this == post || this == story;

  /// A short video (at most 2 minutes) with stories.
  bool get canHaveVideo => this == story;

  static CreateType parse(String? value) => CreateType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => CreateType.post,
  );
}

/// Where a creation goes: the campus General community or the student's
/// specific community.
const generalTarget = 'general';

/// `/create?type=post|question|prayer|story&to=general|<communityId>`: the
/// one place to create anything. "⋯" switches the type; "Post to" picks
/// General or the student's community; anonymous (post, question, prayer)
/// with what it means; a photo for posts; stories need consent and are
/// reviewed before they are published.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, this.type = CreateType.post, this.target});

  final CreateType type;

  /// [generalTarget], a community id, or null (the student's community if
  /// they have one, otherwise General).
  final String? target;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  late CreateType _type = widget.type;
  late String? _target = widget.target;
  final _text = TextEditingController();
  final _title = TextEditingController();
  bool _anonymous = false;
  bool _consent = false;
  String? _photo;
  PickedVideo? _video;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_text, _title]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _title.dispose();
    super.dispose();
  }

  String? get _myCommunityId => approvedCommunityId(
    ref.watch(membershipProvider).valueOrNull ?? Membership.empty,
  );

  /// The chosen target, falling back to the student's community or General.
  String get _to {
    final mine = _myCommunityId;
    final t = _target;
    if (t == generalTarget) return generalTarget;
    if (t != null && t == mine) return t;
    return mine ?? generalTarget;
  }

  bool get _hasContent =>
      _text.text.trim().isNotEmpty ||
      _title.text.trim().isNotEmpty ||
      _photo != null ||
      _video != null;

  bool get _ready {
    if (_sending) return false;
    if (_text.text.trim().isEmpty) return false;
    if (_type == CreateType.story) {
      return _title.text.trim().isNotEmpty && _consent;
    }
    return true;
  }

  String _destination(String communityId) {
    final general = _to == generalTarget;
    return switch (_type) {
      CreateType.post || CreateType.question =>
        general ? '/general-feed' : '/community/$communityId/feed',
      CreateType.prayer =>
        general ? '/general-feed/prayer' : '/community/$communityId/prayer',
      CreateType.story =>
        general
            ? '/general-feed/testimonies'
            : '/community/$communityId/testimonies',
    };
  }

  Future<void> _close() async {
    if (_hasContent) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Discard this?'),
          content: const Text('What you wrote will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    // Opened from a link with nothing behind it: back to where it would post.
    popOr(context, _destination(_to));
  }

  Future<void> _send() async {
    if (!_ready) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    setState(() => _sending = true);
    try {
      final general = _to == generalTarget;
      final communityId = general
          ? (await ref.read(generalCommunityProvider.future)).id
          : _to;
      final now = DateTime.now();
      final anonymous = _type.canBeAnonymous && _anonymous;
      switch (_type) {
        case CreateType.post || CreateType.question:
          final key = (
            communityId: communityId,
            scope: general ? PostScope.general : PostScope.specific,
          );
          await ref
              .read(feedPostsProvider(key).notifier)
              .createPost(
                Post(
                  id: 'post-${now.microsecondsSinceEpoch}',
                  communityId: communityId,
                  scope: key.scope,
                  author: Person(
                    id: profile.id,
                    name: profile.fullName,
                    role: PersonRole.member,
                  ),
                  body: _text.text.trim(),
                  createdAt: now,
                  photo: _type.canHavePhoto && _photo != null
                      ? PostPhoto.file(_photo!)
                      : null,
                  kind: _type == CreateType.question
                      ? PostKind.question
                      : PostKind.post,
                  anonymous: anonymous,
                  isMine: true,
                ),
              );
        case CreateType.prayer:
          await ref
              .read(prayerRequestsProvider(communityId).notifier)
              .createRequest(
                PrayerRequest(
                  id: 'prayer-${now.microsecondsSinceEpoch}',
                  communityId: communityId,
                  authorId: anonymous ? null : profile.id,
                  authorName: anonymous ? null : profile.fullName,
                  anonymous: anonymous,
                  body: _text.text.trim(),
                  createdAt: now,
                ),
              );
        case CreateType.story:
          await ref
              .read(testimoniesProvider(communityId).notifier)
              .submitStory(
                attachments: StoryAttachments(
                  photoPath: _photo,
                  videoPath: _video?.path,
                  videoLength: _video?.duration,
                ),
                Testimony(
                  id: 'testimony-${now.microsecondsSinceEpoch}',
                  communityId: communityId,
                  type: TestimonyType.story,
                  title: _title.text.trim(),
                  excerpt: _text.text.trim(),
                  authorId: profile.id,
                  authorName: profile.fullName,
                  institution: profile.institutionName,
                  status: TestimonyStatus.pending,
                  createdAt: now,
                ),
              );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(switch (_type) {
              CreateType.post => 'Posted',
              CreateType.question => 'Question posted',
              CreateType.prayer => 'Prayer request shared',
              CreateType.story => 'Story sent. It will appear once reviewed.',
            }),
          ),
        );
      context.go(_destination(communityId));
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        showErrorSnack(context, 'It was not sent. Please try again.');
      }
    }
  }

  void _openTypeMenu() => showSectionMenu(context, 'Create', [
    for (final t in CreateType.values)
      SectionMenuItem(
        label: t.label,
        icon: t.icon,
        active: t == _type,
        onSelected: () => setState(() => _type = t),
      ),
  ]);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final myId = _myCommunityId;
    final myName = myId == null
        ? null
        : ref.watch(communityByIdProvider(myId)).valueOrNull?.name;

    return PopScope(
      canPop: !_hasContent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                type: _type,
                canSend: _ready && online,
                sending: _sending,
                onClose: _close,
                onMenu: _openTypeMenu,
                onSend: _send,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (profile != null)
                      Row(
                        children: [
                          InitialsAvatar(
                            initials: _anonymous && _type.canBeAnonymous
                                ? '?'
                                : profile.initials,
                            photoPath: _anonymous && _type.canBeAnonymous
                                ? null
                                : profile.photoPath,
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _anonymous && _type.canBeAnonymous
                                  ? 'Anonymous'
                                  : profile.fullName,
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const _Label('Post to'),
                    const SizedBox(height: 8),
                    _TargetPicker(
                      selected: _to,
                      myCommunityId: myId,
                      myCommunityName: myName,
                      onChanged: (t) => setState(() => _target = t),
                    ),
                    const SizedBox(height: 20),
                    if (_type == CreateType.story) ...[
                      AppTextField(
                        label: 'Title',
                        controller: _title,
                        placeholder: 'Give your story a title',
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 14),
                    ],
                    AppTextArea(
                      label: switch (_type) {
                        CreateType.post => 'Post text',
                        CreateType.question => 'Your question',
                        CreateType.prayer => 'Your request',
                        CreateType.story => 'Your story',
                      },
                      controller: _text,
                      placeholder: switch (_type) {
                        CreateType.post => 'What do you want to share?',
                        CreateType.question =>
                          'Start your question with "How", "Why", "What"...',
                        CreateType.prayer => 'What would you like prayer for?',
                        CreateType.story =>
                          'Tell us what happened and what changed',
                      },
                      minHeight: 140,
                    ),
                    if (_type == CreateType.question) ...[
                      const SizedBox(height: 12),
                      const _Tips(),
                    ],
                    if (_type.canHavePhoto) ...[
                      const SizedBox(height: 14),
                      _PhotoRow(
                        path: _photo,
                        onPick: () async {
                          final picked = await pickPhoto(context, ref);
                          if (picked != null && mounted) {
                            setState(() => _photo = picked.path);
                          }
                        },
                        onRemove: () => setState(() => _photo = null),
                      ),
                    ],
                    if (_type.canHaveVideo) ...[
                      const SizedBox(height: 10),
                      _VideoRow(
                        video: _video,
                        onPick: () async {
                          final picked = await pickVideo(context, ref);
                          if (picked != null && mounted) {
                            setState(() => _video = picked);
                          }
                        },
                        onRemove: () => setState(() => _video = null),
                      ),
                    ],
                    if (_type.canBeAnonymous) ...[
                      const SizedBox(height: 14),
                      SwitchRow(
                        title: switch (_type) {
                          CreateType.question => 'Ask anonymously',
                          _ => 'Post anonymously',
                        },
                        subtitle: _anonymous
                            ? 'Other students will see "Anonymous" instead of '
                                  'your name and photo. Moderators can still '
                                  'see who posted, so they can act on abuse.'
                            : 'Your name and photo will be shown.',
                        value: _anonymous,
                        onChanged: (v) => setState(() => _anonymous = v),
                      ),
                    ],
                    if (_type == CreateType.prayer) ...[
                      const SizedBox(height: 10),
                      const _Note(
                        'Your community will be able to pray and respond.',
                      ),
                    ],
                    if (_type == CreateType.story) ...[
                      const SizedBox(height: 14),
                      CheckRow(
                        label: 'I agree to share my story with my community.',
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v),
                      ),
                      const SizedBox(height: 10),
                      const _Note(
                        'Moderators review every story before it is '
                        'published. It shows your name.',
                      ),
                    ],
                    if (!online) ...[
                      const SizedBox(height: 14),
                      const _Note('You are offline. Sending is paused.'),
                    ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.type,
    required this.canSend,
    required this.sending,
    required this.onClose,
    required this.onMenu,
    required this.onSend,
  });

  final CreateType type;
  final bool canSend;
  final bool sending;
  final VoidCallback onClose;
  final VoidCallback onMenu;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.close_rounded,
            semanticLabel: 'Close',
            onPressed: onClose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              label: 'Create, ${type.label}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create',
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.inkDeemphasized80,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      type.label,
                      style: AppTextStyles.sectionHeading,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          RoundIconButton(
            icon: Icons.more_horiz_rounded,
            semanticLabel: 'Change what you create',
            onPressed: onMenu,
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            enabled: canSend,
            label: type.action,
            excludeSemantics: true,
            child: Opacity(
              opacity: canSend ? 1 : 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: radius,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: canSend ? onSend : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          widthFactor: 1,
                          child: sending
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.ink,
                                  ),
                                )
                              : Text(
                                  type.action,
                                  style: AppTextStyles.cardTitle,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// General community / the student's specific community (disabled with a
/// note when they have none yet).
class _TargetPicker extends StatelessWidget {
  const _TargetPicker({
    required this.selected,
    required this.myCommunityId,
    required this.myCommunityName,
    required this.onChanged,
  });

  final String selected;
  final String? myCommunityId;
  final String? myCommunityName;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TargetChip(
              icon: Icons.public_rounded,
              label: 'General community',
              selected: selected == generalTarget,
              onTap: () => onChanged(generalTarget),
            ),
            _TargetChip(
              icon: Icons.groups_rounded,
              label: myCommunityName ?? 'My community',
              selected: myCommunityId != null && selected == myCommunityId,
              onTap: myCommunityId == null
                  ? null
                  : () => onChanged(myCommunityId!),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Note(
          myCommunityId == null
              ? 'Join a specific community to post there too.'
              : selected == generalTarget
              ? 'Everyone on your campus can see it.'
              : 'Only members of ${myCommunityName ?? 'your community'} can '
                    'see it.',
        ),
      ],
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Material(
          color: selected ? AppColors.honey : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? AppColors.amberDark : AppColors.inputBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? Icons.check_circle_rounded : icon,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.inputBorder, width: 1.5),
            minimumSize: const Size(44, 44),
            shape: const StadiumBorder(),
          ),
          onPressed: onPick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add a photo (optional)'),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Image(
              image: sizedFileImage(context, path!, logicalSize: 360),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: RoundIconButton(
            icon: Icons.close_rounded,
            semanticLabel: 'Remove photo',
            size: 40,
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tips for a good question', style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          for (final tip in const [
            'Keep it short and clear.',
            'One question at a time.',
            'Be kind. No names or private details.',
          ])
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('•  $tip', style: AppTextStyles.body),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.fieldLabel);
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.body.copyWith(
      fontSize: 13.5,
      color: AppColors.inkDeemphasized80,
    ),
  );
}

/// "Add a video (up to 2 minutes)", or the chosen video's length with a
/// remove button.
class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.video,
    required this.onPick,
    required this.onRemove,
  });

  final PickedVideo? video;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final v = video;
    if (v == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide(color: AppColors.inputBorder, width: 1.5),
            minimumSize: const Size(44, 44),
            shape: const StadiumBorder(),
          ),
          onPressed: onPick,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Add a video (up to 2 minutes)'),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline_rounded, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Video · ${v.lengthLabel}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          RoundIconButton(
            icon: Icons.close_rounded,
            semanticLabel: 'Remove video',
            size: 40,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
