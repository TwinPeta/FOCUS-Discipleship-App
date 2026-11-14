import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_secondary_button.dart';

/// Question and answer pairs on Help & FAQ (screen 50).
const helpFaq = <(String, String)>[
  (
    'Why can I join only one specific community?',
    'A smaller group lets mentors know you well. You stay in your general '
        'campus community, and you can change by leaving your specific one '
        'first.',
  ),
  (
    'How do I join a specific community?',
    'Open Communities, choose a community at your campus and tap Request to '
        'join. Its super-mentor approves or declines, and you get a '
        'notification either way.',
  ),
  (
    'How do I report a post or a person?',
    'Tap the "..." on a post, or the flag on a prayer request, testimony or '
        'conversation, and choose Report. Pick a reason; a super-mentor '
        'reviews it. Reports are private.',
  ),
  (
    'How do I change my photo?',
    'Go to Settings, then Edit profile, and tap your photo. Choose a new one '
        'from your camera or gallery, then Save changes.',
  ),
];

/// Screen 50: Help & FAQ (`/help`, public). The first answer starts open.
/// Also the target of ErrorView's "Contact support".
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Support email copied: $supportEmail')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      title: 'Help & FAQ',
      subtitle: 'Answers to common questions',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.cardSmall),
            child: Material(
              color: AppColors.white,
              child: Theme(
                // No divider lines from ExpansionTile; we draw our own.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (var i = 0; i < helpFaq.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.cream),
                      ExpansionTile(
                        initiallyExpanded: i == 0,
                        iconColor: AppColors.ink,
                        collapsedIconColor: AppColors.ink,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedAlignment: Alignment.centerLeft,
                        title: Text(
                          helpFaq[i].$1,
                          style: AppTextStyles.bodyMedium,
                        ),
                        children: [
                          Text(
                            helpFaq[i].$2,
                            style: AppTextStyles.body.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Still need help? Write to the support team.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          AppSecondaryButton(
            label: 'Copy support email',
            icon: Icons.copy_rounded,
            height: 48,
            onPressed: () => _copyEmail(context),
          ),
          const SizedBox(height: 6),
          Text(
            supportEmail,
            textAlign: TextAlign.center,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
