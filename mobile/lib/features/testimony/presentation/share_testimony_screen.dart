import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/check_row.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/testimony.dart';
import 'providers/testimony_providers.dart';

/// Screen 17: Share a testimony, reached from the Testimonies tab.
class ShareTestimonyScreen extends ConsumerStatefulWidget {
  const ShareTestimonyScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<ShareTestimonyScreen> createState() =>
      _ShareTestimonyScreenState();
}

class _ShareTestimonyScreenState extends ConsumerState<ShareTestimonyScreen> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  bool _consent = false;
  bool _isSubmitting = false;
  String? _photoName;
  String? _videoName;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _titleController.text.trim().isNotEmpty &&
      _storyController.text.trim().isNotEmpty &&
      _consent;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _photoName = picked.name);
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _videoName = picked.name);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;

    setState(() => _isSubmitting = true);
    final testimony = Testimony(
      id: 'testimony-${DateTime.now().microsecondsSinceEpoch}',
      communityId: widget.communityId,
      type: TestimonyType.story,
      title: _titleController.text.trim(),
      excerpt: _storyController.text.trim(),
      authorName: profile.fullName,
      institution: profile.institutionName,
      status: TestimonyStatus.pending,
      createdAt: DateTime.now(),
      isMine: true,
    );

    await ref
        .read(testimoniesProvider(widget.communityId).notifier)
        .submitStory(testimony);

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      title: 'Share your story',
      subtitle: 'A story of how your life or heart changed.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Title',
              controller: _titleController,
              placeholder: 'Give your story a title',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            AppTextArea(
              label: 'Your story',
              controller: _storyController,
              placeholder: 'Share what happened and how it changed you…',
              minHeight: 130,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: _photoName ?? 'Add photo',
                    icon: Icons.image_outlined,
                    height: 46,
                    onPressed: _pickPhoto,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSecondaryButton(
                    label: _videoName ?? 'Add video',
                    icon: Icons.videocam_outlined,
                    height: 46,
                    onPressed: _pickVideo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CheckRow(
              label: 'I agree to share my story with my community.',
              value: _consent,
              onChanged: (value) => setState(() => _consent = value),
            ),
            const SizedBox(height: 10),
            const Text(
              'Moderators review every story before it is published.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.placeholder,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      bottomBar: AppPrimaryButton(
        label: 'Submit for review',
        height: 54,
        isLoading: _isSubmitting,
        onPressed: _canSubmit ? _submit : null,
      ),
    );
  }
}
