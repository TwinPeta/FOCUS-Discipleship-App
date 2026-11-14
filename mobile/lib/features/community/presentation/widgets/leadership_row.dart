import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/person.dart';

class LeadershipRow extends StatelessWidget {
  const LeadershipRow({
    super.key,
    required this.person,
    required this.roleLabel,
    required this.color,
  });

  final Person person;
  final String roleLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(person.initials, style: AppTextStyles.cardTitle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleLabel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.inkDeemphasized80,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
