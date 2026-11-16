import 'package:material_ui/material_ui.dart';

/// [text] with one word per line, each word shrinking to the available
/// width instead of breaking inside it (short card titles at large text
/// sizes, e.g. "General" / "community").
class FittedBoxWords extends StatelessWidget {
  const FittedBoxWords(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final word in text.split(' '))
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(word, style: style, maxLines: 1),
            ),
        ],
      ),
    );
  }
}
