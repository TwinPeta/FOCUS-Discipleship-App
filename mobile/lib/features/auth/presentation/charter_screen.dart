import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/amber_header_scaffold.dart';

/// Read-only community charter (`/charter`), reachable signed in or out.
/// Placeholder wording until FCU supplies the final charter.
class CharterScreen extends StatelessWidget {
  const CharterScreen({super.key});

  /// Short version shown on the consent card.
  static const summary = [
    'Treat everyone with kindness and respect.',
    'Keep what is shared in the caregroup private.',
    'No harassment, hate or inappropriate content.',
    'Mentors guide; report anything that worries you.',
  ];

  static const _sections = <(String, String)>[
    (
      'Respect',
      '[Placeholder] We welcome every student. Disagree kindly, never '
          'insult, mock or exclude anyone.',
    ),
    (
      'Privacy',
      '[Placeholder] Prayer requests, testimonies and messages stay inside '
          'the caregroup. Do not share screenshots without permission.',
    ),
    (
      'Safety',
      '[Placeholder] No harassment, bullying, hate speech or sexual '
          'content. Adults and minors follow FCU safeguarding rules.',
    ),
    (
      'Reporting',
      '[Placeholder] Use Report on any post, comment or person. Moderators '
          'review every report; admins handle suspensions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AmberHeaderScaffold(
      title: 'Caregroup charter',
      subtitle: 'How we look after one another.',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (title, text) in _sections) ...[
            Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.sectionHeading),
            ),
            const SizedBox(height: 6),
            Text(text, style: AppTextStyles.body.copyWith(height: 1.5)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
