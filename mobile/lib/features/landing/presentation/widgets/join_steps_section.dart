import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'bold_style.dart';

class _StepData {
  const _StepData({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}

const _steps = [
  _StepData(
    number: 1,
    title: 'Create your profile',
    description: 'Add your photo and details in a minute.',
  ),
  _StepData(
    number: 2,
    title: 'Enter your campus',
    description: 'You join the general community automatically.',
  ),
  _StepData(
    number: 3,
    title: 'Pick one specific community',
    description: 'A smaller group with mentors. One per student.',
  ),
];

class JoinStepsSection extends StatelessWidget {
  const JoinStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join in 3 steps', style: AppTextStyles.landingSectionH2),
          const SizedBox(height: 20),
          for (final step in _steps) ...[
            _StepRow(data: step),
            if (step != _steps.last) const SizedBox(height: 18),
          ],
          const SizedBox(height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniCard(
                  title: 'General',
                  description: 'Everyone on your campus, open to all.',
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _MiniCard(
                  title: 'Specific',
                  description: 'Your small group with a super-mentor.',
                  color: AppColors.honey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${data.number}',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(data.description, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.title,
    required this.description,
    required this.color,
  });

  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: boldCardDecoration(
        color: color,
        radius: 20,
        shadowOffset: const Offset(3, 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
