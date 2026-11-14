import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/password_policy.dart';
import 'app_text_field.dart';

/// [AppTextField] with a show/hide toggle. Never logs or echoes its value.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.errorText,
    this.onChanged,
    this.newPassword = false,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// Sign-up fields hint `newPassword`; sign-in fields hint `password`.
  final bool newPassword;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      focusNode: widget.focusNode,
      placeholder: widget.placeholder,
      errorText: widget.errorText,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.placeholder,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// Live rule checklist under a new-password field. Uses icons and words,
/// not colour alone.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({
    super.key,
    required this.password,
    this.repeat,
  });

  final String password;

  /// When given (and non-empty), a mismatch line is shown.
  final String? repeat;

  @override
  Widget build(BuildContext context) {
    final mismatch = repeat != null && repeat!.isNotEmpty && repeat != password;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rule(
          met: PasswordPolicy.hasMinLength(password),
          label: 'At least ${PasswordPolicy.minLength} characters',
        ),
        _Rule(
          met: PasswordPolicy.hasLetterAndNumber(password),
          label: 'A letter and a number',
        ),
        if (mismatch)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'The passwords do not match',
              style: AppTextStyles.fieldLabel.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${met ? 'done' : 'not yet'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 18,
              color: met ? AppColors.ink : AppColors.placeholder,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
