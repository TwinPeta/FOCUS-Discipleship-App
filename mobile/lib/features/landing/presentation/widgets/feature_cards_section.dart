import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'bold_style.dart';

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
    description: 'Videos, guides and quizzes to grow, in class and beyond.',
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
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus life is better together',
            style: AppTextStyles.landingSectionH2,
          ),
          const SizedBox(height: 20),
          for (final feature in _features) ...[
            _FeatureCard(data: feature),
            if (feature != _features.last) const SizedBox(height: 16),
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
      decoration: boldCardDecoration(color: AppColors.white, radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 2),
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
                  style: AppTextStyles.sectionHeading.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(data.description, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
