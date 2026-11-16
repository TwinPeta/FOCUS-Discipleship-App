import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/feature_cards_section.dart';
import 'widgets/final_cta_section.dart';
import 'widgets/join_steps_section.dart';
import 'widgets/landing_hero_section.dart';
import 'widgets/stories_section.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _storiesKey = GlobalKey();

  void _scrollToStories() {
    final storiesContext = _storiesKey.currentContext;
    if (storiesContext != null) {
      Scrollable.ensureVisible(
        storiesContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LandingHeroSection(onWatchStories: _scrollToStories),
            const FeatureCardsSection(),
            KeyedSubtree(key: _storiesKey, child: const StoriesSection()),
            const JoinStepsSection(),
            const FinalCtaSection(),
          ],
        ),
      ),
    );
  }
}
