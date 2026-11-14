import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/error_snack.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/privacy_repository.dart';
import 'delete_account_sheet.dart';
import 'settings_screen.dart';

/// Screen 48: Privacy & data (`/settings/privacy`).
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  var _exporting = false;

  Future<void> _download() async {
    final session = ref.read(authSessionProvider);
    if (_exporting || session == null) return;
    setState(() => _exporting = true);
    try {
      await ref
          .read(privacyRepositoryProvider)
          .requestDataExport(session.accountId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('We will email you a copy at ${session.email}.'),
          ),
        );
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    void open(String route) => unawaited(context.push(route));
    return AmberHeaderScaffold(
      title: 'Privacy & data',
      subtitle: 'You control your information.',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SettingsRow(
            icon: Icons.download_outlined,
            title: 'Download my data',
            subtitle: _exporting
                ? 'Requesting…'
                : 'Get a copy of your information',
            onTap: online && !_exporting ? _download : null,
          ),
          const SizedBox(height: 10),
          SettingsRow(
            icon: Icons.emoji_events_outlined,
            title: 'My activity & badges',
            subtitle: 'Only you can see this',
            onTap: () => open('/activity'),
          ),
          const SizedBox(height: 10),
          SettingsRow(
            icon: Icons.block_rounded,
            title: 'Blocked users',
            subtitle: 'People who cannot message you',
            onTap: () => open('/settings/blocked'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              'Only you can see your activity history. Your data is kept for '
              '$dataRetentionMonths months after your last activity.',
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            child: OutlinedButton.icon(
              onPressed: online ? () => showDeleteAccountSheet(context) : null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Delete my account',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
