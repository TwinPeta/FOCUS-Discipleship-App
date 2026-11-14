import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../../core/widgets/switch_row.dart';
import '../domain/notification_preferences.dart';
import 'notification_providers.dart';

/// Screen 45: Notification settings (`/notifications/settings`). Every
/// switch saves immediately; muting a category stops new notifications of
/// that kind from being created.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() save,
  ) async {
    try {
      await save();
    } catch (_) {
      if (context.mounted) {
        showErrorSnack(context, 'Could not save. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final controller = ref.read(notificationPreferencesProvider.notifier);
    return AmberHeaderScaffold(
      title: 'Notification settings',
      subtitle: 'Choose what you hear about.',
      body: prefs.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 2),
        error: (_, _) => ErrorView(
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Channels', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 8),
            _Group(
              children: [
                for (final c in DeliveryChannel.values)
                  SwitchRow(
                    title: c.label,
                    value: p.usesChannel(c),
                    onChanged: (on) =>
                        _guard(context, () => controller.setChannel(c, on)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Notify me about', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 8),
            _Group(
              children: [
                for (final c in NotificationCategory.values)
                  SwitchRow(
                    title: c.label,
                    value: p.isEnabled(c),
                    onChanged: (on) =>
                        _guard(context, () => controller.setCategory(c, on)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Moderator warnings are always shown.',
              style: AppTextStyles.body.copyWith(color: AppColors.placeholder),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      child: Material(
        color: AppColors.white,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.cream),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
