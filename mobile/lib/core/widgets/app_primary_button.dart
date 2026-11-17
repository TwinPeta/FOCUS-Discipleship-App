import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Amber primary action button used on every screen except the landing page.
/// Enabled: the brand gradient; disabled: flat, faded amber.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.button);
    // Min height (not fixed) so 2.0x text never clips the label. The
    // gradient sits behind a transparent button so the ripple still shows.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isDisabled ? null : AppGradients.brand,
          color: _isDisabled
              ? AppColors.amberLight.withValues(alpha: 0.5)
              : null,
          borderRadius: radius,
        ),
        child: ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.ink,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.ink,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
