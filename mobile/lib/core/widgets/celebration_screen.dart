import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_gradients.dart';

/// Full-screen result: centred 112px amber circle with an icon, a 34/w900
/// title, a body, optional extra content and stacked actions. Used by the
/// request results and the badge-earned screen.
class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.extra = const [],
    required this.actions,
    this.iconBackground = AppColors.amber,
  });

  final IconData icon;
  final String title;

  /// Plain or rich text; wrap in [Text] / [Text.rich].
  final Widget body;
  final List<Widget> extra;
  final List<Widget> actions;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: iconBackground,
                          gradient: iconBackground == AppColors.amber
                              ? AppGradients.brand
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 56, color: AppColors.ink),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.celebrationTitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: DefaultTextStyle.merge(
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 18,
                            height: 1.4,
                          ),
                          child: body,
                        ),
                      ),
                      if (extra.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...extra,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cream info row used inside celebration screens (meeting day, room…).
class CelebrationInfoRow extends StatelessWidget {
  const CelebrationInfoRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
