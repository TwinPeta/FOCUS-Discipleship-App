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
