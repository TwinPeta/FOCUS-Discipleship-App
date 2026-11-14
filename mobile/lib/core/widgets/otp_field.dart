import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Six single-digit boxes backed by one hidden numeric field, so typing
/// auto-advances, backspace moves back, pasting 6 digits fills every box
/// and the platform can autofill a one-time code.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final int length;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: GestureDetector(
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: Stack(
          children: [
            // The real input: invisible but focusable and autofillable.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 56,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: widget.length,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: _onChanged,
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _box(i, text)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int index, String text) {
    final active =
        _focusNode.hasFocus &&
        (index == text.length ||
            (index == widget.length - 1 && text.length == widget.length));
    final borderColor = widget.hasError
        ? AppColors.error
        : active
        ? AppColors.ink
        : AppColors.inputBorder;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.enabled ? AppColors.white : AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor, width: active ? 2 : 1.5),
      ),
      child: Text(
        index < text.length ? text[index] : '',
        style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
      ),
    );
  }
}
