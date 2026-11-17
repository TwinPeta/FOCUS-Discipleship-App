import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'landing_pill_button.dart';

/// Last block of the landing page: gradient card with the main call to
/// action and a sign-in link for existing members.
class FinalCtaSection extends StatelessWidget {
  const FinalCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        36,
        16,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ready to meet your people?',
            style: AppTextStyles.landingFinalCtaH2,
          ),
          const SizedBox(height: 14),
          Text(
            'Changing Students, Transforming Societies.',
            style: AppTextStyles.body.copyWith(fontSize: 18, height: 1.35),
          ),
          const SizedBox(height: 18),
          LandingPillButton(
            label: 'Explore communities',
            expand: true,
            onPressed: () => context.push('/join/start'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Semantics(
              button: true,
              label: 'Already a member? Sign in',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => context.push('/login'),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    widthFactor: 1,
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.body.copyWith(fontSize: 16),
                        children: const [
                          TextSpan(text: 'Already a member? '),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
