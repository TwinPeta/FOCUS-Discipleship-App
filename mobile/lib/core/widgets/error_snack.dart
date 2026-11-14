import 'package:material_ui/material_ui.dart';

/// One consistent snackbar for failed user actions (submit, send, block…).
void showErrorSnack(
  BuildContext context, [
  String message = 'Something went wrong. Please try again.',
]) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
