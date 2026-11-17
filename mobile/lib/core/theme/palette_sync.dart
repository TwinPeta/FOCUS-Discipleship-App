import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Keeps [AppColors] on the light or dark palette of the current theme.
/// Screens read colours directly from [AppColors], so when the palette
/// changes every widget below is rebuilt and repainted (even `const` ones,
/// which Flutter would otherwise reuse unchanged).
class PaletteSync extends StatelessWidget {
  const PaletteSync({super.key, required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppColors.isDark != dark) {
      AppColors.usePalette(dark: dark);
      // Marking descendants dirty during this build is allowed; they are
      // rebuilt later in this same frame with the new palette.
      void refresh(Element e) {
        e.markNeedsBuild();
        if (e is RenderObjectElement) e.renderObject.markNeedsPaint();
        e.visitChildren(refresh);
      }

      (context as Element).visitChildren(refresh);
    }
    return child;
  }
}
