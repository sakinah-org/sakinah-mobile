import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Logout confirmation (spec.md FR-014/FR-016) — a single confirm/cancel
/// step, no dedicated design mock for this dialog, so it follows a plain
/// `AlertDialog` styled with the app's existing tokens.
class SettingsLogoutConfirmationDialog extends StatelessWidget {
  const SettingsLogoutConfirmationDialog({super.key});

  /// Returns `true` if the user confirmed, `false`/`null` otherwise.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const SettingsLogoutConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const error = AppColors.error;

    return AlertDialog(
      title: Text(
        translator.word(TranslationKeys.settingsLogoutConfirmTitle),
        style: const TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        translator.word(TranslationKeys.settingsLogoutConfirmMessage),
        style: const TextStyle(fontFamily: AppTypography.uiFontFamily),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(translator.word(TranslationKeys.settingsLogoutCancelCta)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            translator.word(TranslationKeys.settingsLogoutConfirmCta),
            style: const TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              color: error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
