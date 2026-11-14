import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

/// 10px ink-on-white progress bar used by the current-pathway card and the
/// steps header.
class PathwayProgressBar extends StatelessWidget {
  const PathwayProgressBar({super.key, required this.progress});

  /// 0..1
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0, 1) * 100).round();
    return Semantics(
      label: 'Progress',
      value: '$percent percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0, 1).toDouble(),
            child: Container(color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
