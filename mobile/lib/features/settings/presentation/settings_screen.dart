import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/initials.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/list_row_card.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../profile/presentation/profile_providers.dart';

const _tileSize = 48.0;
const _avatarSize = 56.0;

/// Screen 46: Settings (`/settings`). Back goes to My profile.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in any time with your email and password.',
      confirmLabel: 'Sign out',
    );
    if (!ok || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        showErrorSnack(context);
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    void open(String route) => unawaited(context.push(route));

    return AmberHeaderScaffold(
      title: 'Settings',
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      body: profile == null
          ? const Skeleton(showHeader: false, cardCount: 2)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Semantics(
                  button: true,
                  label: 'Edit profile, ${profile.fullName}',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                    child: InkWell(
                      onTap: () => open('/settings/profile'),
                      borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadii.cardSmall,
                          ),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(
                              initials: initialsOf(profile.fullName),
                              photoPath: profile.photoPath,
                              size: _avatarSize,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  Text(
                                    '@${profile.username} · '
                                    '${profile.institutionName}',
                                    style: AppTextStyles.body,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final row in _rows) ...[
                  SettingsRow(
                    icon: row.icon,
                    title: row.title,
                    subtitle: row.subtitle,
                    // Language: one language for now, so nothing to open.
                    onTap: row.route == null ? null : () => open(row.route!),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                AppSecondaryButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  height: 48,
                  isLoading: _signingOut,
                  onPressed: _signingOut ? null : _signOut,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  // Debug builds only: long-press opens the scenario registry.
                  onLongPress: kDebugMode ? () => open('/debug') : null,
                  child: Text(
                    'Version $appVersion',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.placeholder,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

typedef _Row = ({IconData icon, String title, String subtitle, String? route});

const List<_Row> _rows = [
  (
    icon: Icons.person_outline_rounded,
    title: 'Edit profile',
    subtitle: 'Photo, name, phone',
    route: '/settings/profile',
  ),
  (
    icon: Icons.notifications_none_rounded,
    title: 'Notifications',
    subtitle: 'In-app and email',
    route: '/notifications/settings',
  ),
  (
    icon: Icons.language_rounded,
    title: 'Language',
    subtitle: 'English',
    route: null,
  ),
  (
    icon: Icons.shield_outlined,
    title: 'Privacy & data',
    subtitle: 'Download or delete my data',
    route: '/settings/privacy',
  ),
  (
    icon: Icons.help_outline_rounded,
    title: 'Help & FAQ',
    subtitle: 'Answers and contact',
    route: '/help',
  ),
];

/// A settings row: icon tile, title, subtitle, chevron. Shared by Settings
/// (46) and Privacy & data (48).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListRowCard(
      leading: Container(
        width: _tileSize,
        height: _tileSize,
        decoration: BoxDecoration(
          color: AppColors.honey,
          borderRadius: BorderRadius.circular(AppRadii.tile),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
    );
  }
}
