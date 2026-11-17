import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_gradients.dart';

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _features = [
  _FeatureCardData(
    icon: Icons.groups_rounded,
    title: 'Connect',
    description: 'Meet students on your campus who share your values.',
  ),
  _FeatureCardData(
    icon: Icons.menu_book_rounded,
    title: 'Learn',
    description:
        'Videos, devotionals and quizzes to grow, in class and beyond.',
  ),
  _FeatureCardData(
    icon: Icons.bar_chart_rounded,
    title: 'Succeed',
    description: 'Mentors who cheer you on toward your goals.',
  ),
];

class FeatureCardsSection extends StatelessWidget {
  const FeatureCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus life is better together',
            style: AppTextStyles.landingSectionH2,
          ),
          const SizedBox(height: 18),
          for (final feature in _features) ...[
            _FeatureCard(data: feature),
            if (feature != _features.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 28, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTextStyles.sectionHeading.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
