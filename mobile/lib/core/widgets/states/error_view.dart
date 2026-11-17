import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../app_primary_button.dart';
import '../app_secondary_button.dart';

/// Full-area failure state. [onRetry] re-runs the failed call; "Contact
/// support" opens `/help` (a placeholder until prompt 3).
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.onRetry,
    this.title = 'Something went wrong',
    this.message = 'We could not load this page. Please try again.',
  });

  final VoidCallback? onRetry;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.sectionHeading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (onRetry != null) ...[
                AppPrimaryButton(
                  label: 'Try again',
                  height: 48,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 10),
              ],
              AppSecondaryButton(
                label: 'Contact support',
                height: 48,
                onPressed: () => context.push('/help'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [ErrorView] as a whole screen, with a back button (router errorBuilder,
/// unknown ids).
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
            Expanded(child: ErrorView(onRetry: onRetry)),
          ],
        ),
      ),
    );
  }
}
