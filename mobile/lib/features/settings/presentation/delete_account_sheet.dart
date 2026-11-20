import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/bottom_sheet_scaffold.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/password_field.dart';
import '../../auth/data/auth_repository.dart';
import '../data/privacy_repository.dart';
import 'account_deletion.dart';

/// Screen 49: Delete your account? (bottom sheet over Privacy & data).
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _password = TextEditingController();
  String? _error;
  var _deleting = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || _password.text.isEmpty) return;
    setState(() => _deleting = true);
    // Capture before the sheet (and this context) go away.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountDeletionProvider).delete(_password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      router.go('/login');
      messenger.showSnackBar(
        const SnackBar(content: Text('Your account was deleted.')),
      );
    } on InvalidCredentials {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = 'That password is not correct.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        showErrorSnack(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _password.text.isNotEmpty && !_deleting;
    return BottomSheetScaffold(
      title: 'Delete your account?',
      children: [
        Text(
          'Your profile, posts and messages are deleted within '
          '$deletionWindowDays days.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 6),
        Text(
          'You leave all caregroups. This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        PasswordField(
          label: 'Password',
          controller: _password,
          placeholder: 'Enter your password to confirm',
          errorText: _error,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _delete(),
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: 'Keep my account',
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 54,
            minWidth: double.infinity,
          ),
          child: OutlinedButton(
            onPressed: canDelete ? _delete : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: canDelete ? AppColors.error : AppColors.inputBorder,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: _deleting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text(
                    'Delete my account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }
}
