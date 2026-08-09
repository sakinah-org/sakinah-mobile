import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Placeholder destination for the Home prayer card's edit affordance.
/// The full Prayers settings screen (location + calculation method) is a
/// separate, not-yet-specified feature — see specs/002-home-page/research.md §6.
class PrayersPage extends StatelessWidget {
  const PrayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(translator.word(TranslationKeys.prayersPlaceholderTitle)),
      ),
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Center(
        child: Text(
          translator.word(TranslationKeys.prayersPlaceholderMessage),
          style: isDark ? AppTypography.body1Dark : AppTypography.body1Light,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
