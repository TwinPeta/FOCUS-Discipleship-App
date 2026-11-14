import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../widgets/amber_header_scaffold.dart';
import '../widgets/error_snack.dart';
import 'debug_scenarios.dart';

/// Debug-only list of scenarios (opened by long-pressing the name on My
/// profile). Independent of Settings so it survives prompt 3.
class DebugScenariosScreen extends ConsumerWidget {
  const DebugScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();
    final scenarios = ref.watch(debugScenariosProvider);

    return AmberHeaderScaffold(
      title: 'Debug scenarios',
      subtitle: 'Debug builds only.',
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: scenarios.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final scenario = scenarios[index];
          final showGroup =
              index == 0 || scenarios[index - 1].group != scenario.group;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGroup) ...[
                Text(
                  scenario.group.toUpperCase(),
                  style: AppTextStyles.eyebrow,
                ),
                const SizedBox(height: 6),
              ],
              Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.cardSmall),
                child: ListTile(
                  minTileHeight: 56,
                  title: Text(scenario.name, style: AppTextStyles.cardTitle),
                  subtitle: Text(
                    scenario.description,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () async {
                    try {
                      final message = await scenario.run(ref, context);
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    } catch (e) {
                      if (context.mounted) showErrorSnack(context, '$e');
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
