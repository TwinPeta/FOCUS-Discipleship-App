import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'app_chip.dart';

/// Role pill: Super-mentor and Campus team render honey, everything else
/// (Mentor, Student, Member, ...) renders cream.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.label});

  final String label;

  static const _honeyLabels = {'Super-mentor', 'Campus team'};

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      backgroundColor: _honeyLabels.contains(label)
          ? AppColors.honey
          : AppColors.cream,
    );
  }
}
