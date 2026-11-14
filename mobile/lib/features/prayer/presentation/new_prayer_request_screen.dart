import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_area.dart';
import '../../../core/widgets/check_row.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/prayer_request.dart';
import 'providers/prayer_providers.dart';

/// Screen 15: New prayer request, reached from the Prayer wall tab.
class NewPrayerRequestScreen extends ConsumerStatefulWidget {
  const NewPrayerRequestScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<NewPrayerRequestScreen> createState() =>
      _NewPrayerRequestScreenState();
}

class _NewPrayerRequestScreenState
    extends ConsumerState<NewPrayerRequestScreen> {
  final _controller = TextEditingController();
  bool _anonymous = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPost => !_isPosting && _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canPost) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;

    setState(() => _isPosting = true);
    final request = PrayerRequest(
      id: 'prayer-${DateTime.now().microsecondsSinceEpoch}',
      communityId: widget.communityId,
      authorId: _anonymous ? null : profile.id,
      authorName: _anonymous ? null : profile.fullName,
      anonymous: _anonymous,
      body: _controller.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref
        .read(prayerRequestsProvider(widget.communityId).notifier)
        .createRequest(request);

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      title: 'New prayer request',
      subtitle: 'Your community will be able to pray and respond.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextArea(
              label: 'Your request',
              controller: _controller,
              placeholder: 'Share what\'s on your heart…',
              minHeight: 150,
              fontSize: 17,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            CheckRow(
              label: 'Post anonymously',
              value: _anonymous,
              onChanged: (value) => setState(() => _anonymous = value),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.placeholder),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requests are visible to members of your specific community.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomBar: AppPrimaryButton(
        label: 'Post request',
        height: 54,
        isLoading: _isPosting,
        onPressed: _canPost ? _submit : null,
      ),
    );
  }
}
