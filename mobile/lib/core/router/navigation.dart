import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Goes back one page, or, when there is nothing to pop (the screen was
/// opened from a deep link or a notification), goes to [fallback], the
/// screen's logical parent. Every Back, Close and "done" action uses this,
/// so no screen is ever a dead end.
void popOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Makes the phone's Back button do what this screen's own Back does.
///
/// Many screens are reached with `go` (bottom bar, "⋯" menu, links from
/// the hub), which leaves nothing to pop, so Android used to close the
/// app. Now, when there is nothing to pop, [onBack] runs instead (the
/// same fallback as the on-screen Back). With [onBack] null (Home), the
/// app closes as usual. Open sheets and dialogs, and normal pops (which
/// respect `PopScope`), are left to the router.
class SystemBack extends StatelessWidget {
  const SystemBack({super.key, required this.onBack, required this.child});

  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        final action = onBack;
        if (action == null || !context.mounted) return false;
        // A tab kept alive offstage, or a sheet/dialog on top: not ours.
        if (!TickerMode.valuesOf(context).enabled) return false;
        if (ModalRoute.of(context)?.isCurrent == false) return false;
        if (context.canPop()) return false;
        action();
        return true;
      },
      child: child,
    );
  }
}
