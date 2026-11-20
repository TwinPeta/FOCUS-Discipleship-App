import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'app_chip.dart';

/// Role pill: Super-mentor and Campus team render honey, everything else
/// (Mentor, Student, Member, ...) renders cream.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.label});

  final String label;

  // Carebook: super-mentor gold, mentor soft gold, everyone else pale blue.
  static const _goldLabels = {'Super-mentor', 'Campus team'};

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      backgroundColor: _goldLabels.contains(label)
          ? AppColors.amberLight
          : label == 'Mentor'
          ? AppColors.honey
          : AppColors.primarySoft,
    );
  }
}
