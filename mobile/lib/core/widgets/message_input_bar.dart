import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

import 'package:flutter/services.dart';

import '../media/upload_policy.dart';

/// Rounded text field plus a 50px amber send button. Used by the
/// conversation (screen 10) and post comments (screen 39). When [enabled]
/// is false (e.g. offline) both stay visible but inactive.
class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hintText,
    this.enabled = true,
    this.sendLabel = 'Send',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final bool enabled;
  final String sendLabel;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              enabled: enabled,
              inputFormatters: [
                LengthLimitingTextInputFormatter(UploadPolicy.maxMessageChars),
              ],
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.placeholder),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: border(AppColors.inputBorder),
                enabledBorder: border(AppColors.inputBorder),
                disabledBorder: border(AppColors.inputBorder),
                focusedBorder: border(AppColors.ink),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = enabled && value.text.trim().isNotEmpty;
            return Semantics(
              button: true,
              enabled: canSend,
              label: sendLabel,
              child: InkWell(
                onTap: canSend ? onSend : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: canSend
                        ? AppColors.amber
                        : AppColors.amber.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.send_rounded, color: AppColors.ink),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
