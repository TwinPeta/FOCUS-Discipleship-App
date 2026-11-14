import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Shows [child] (normally a [BottomSheetScaffold]) as a modal sheet over a
/// 50% ink scrim.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: builder,
  );
}

/// White sheet with 28px top corners, a 44x5 handle, an optional title and
/// stacked content. Scrolls when content is taller than the screen.
class BottomSheetScaffold extends StatelessWidget {
  const BottomSheetScaffold({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.headerBottom),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (title != null) ...[
                Text(
                  title!,
                  style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 14),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
