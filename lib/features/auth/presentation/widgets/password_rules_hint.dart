import 'package:flutter/material.dart';
import 'package:sakinah/configurations/app_translation_keys.dart';
import 'package:sakinah/handlers/translation_handler.dart';
import 'package:sakinah/utils/style/app_typography.dart';

/// Static hint row shown under the new-password field on the Reset
/// Password screen, matching the imported design's copy.
class PasswordRulesHint extends StatelessWidget {
  const PasswordRulesHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        translator.word(TranslationKeys.authPasswordRulesHint),
        style: AppTypography.body3Light,
      ),
    );
  }
}
