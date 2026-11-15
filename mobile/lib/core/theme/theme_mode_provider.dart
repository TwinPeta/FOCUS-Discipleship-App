import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The user's colour mode (Light / Dark / System), roadmap A0.3.
/// Contract shared by the theme work (main.dart) and Settings > Appearance:
/// read with `ref.watch(themeModeProvider)`, change with
/// `ref.read(themeModeProvider.notifier).set(mode)`. In memory for now
/// (persisting needs a storage package).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
