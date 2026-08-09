import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/bloc/session_cubit.dart';
import '../../../../toolkit/extensions/date_time_extensions.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Greeting ("Good evening, {name}") + day name + Hijri date, matching the
/// Home screen mock's header block. Guest-safe: greeting renders without a
/// name segment when no user is signed in (spec.md FR-016).
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key});

  String _greetingKey(GreetingPeriod period) {
    switch (period) {
      case GreetingPeriod.morning:
        return TranslationKeys.homeGreetingMorning;
      case GreetingPeriod.afternoon:
        return TranslationKeys.homeGreetingAfternoon;
      case GreetingPeriod.evening:
        return TranslationKeys.homeGreetingEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);

    final greeting = translator.word(_greetingKey(now.greetingPeriod));
    final name = SessionCubit.instance.currentUser?.name;
    final greetingLine = (name == null || name.isEmpty)
        ? greeting
        : '$greeting${translator.word(TranslationKeys.homeGreetingNameSeparator)}$name';

    final dateLine =
        '${now.dayNameLabel(locale)} · ${now.hijriDateLabel(locale)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          greetingLine,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          dateLine,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
