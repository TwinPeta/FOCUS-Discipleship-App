import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';

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
    description: 'Add your photo and details in about a minute.',
  ),
  _StepData(
    number: 2,
    title: 'Enter your campus',
    description: 'You join the general caregroup automatically.',
  ),
  _StepData(
    number: 3,
    title: 'Pick one specific caregroup',
    description: 'A smaller group with mentors. One per student.',
  ),
];

/// "Join in 3 steps": numbered timeline, then the General / Specific cards.
class JoinStepsSection extends StatelessWidget {
  const JoinStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join in 3 steps', style: AppTextStyles.landingSectionH2),
          const SizedBox(height: 16),
          for (final step in _steps)
            _StepRow(data: step, last: step == _steps.last),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MiniCard(
                    icon: Icons.public_rounded,
                    title: 'General',
                    description: 'Everyone on your campus, open to all.',
                    color: AppColors.honey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniCard(
                    icon: Icons.groups_rounded,
                    title: 'Specific',
                    description: 'Your small group with a super-mentor.',
                    color: AppColors.white,
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

class _StepRow extends StatelessWidget {
  const _StepRow({required this.data, required this.last});

  final _StepData data;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${data.number}',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textScaler: TextScaler.noScaling,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 3,
                    constraints: const BoxConstraints(minHeight: 30),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.honey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.description,
                    style: AppTextStyles.body.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.lifted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.3),
          ),
        ],
      ),
    );
  }
}
