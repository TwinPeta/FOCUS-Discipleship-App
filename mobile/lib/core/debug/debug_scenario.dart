import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A named, one-tap state change for prototyping (debug builds only).
/// Features declare theirs in a `*_debug_scenarios.dart` list and add it to
/// [debugScenariosProvider].
class DebugScenario {
  const DebugScenario({
    required this.group,
    required this.name,
    required this.description,
    required this.run,
  });

  final String group;
  final String name;
  final String description;

  /// Returns an optional confirmation message for the snackbar.
  final Future<String?> Function(WidgetRef ref, BuildContext context) run;
}
