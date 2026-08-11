import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/surah.dart';
import '../bloc/surah_reading_cubit.dart';
import '../bloc/surah_reading_state.dart';
import '../widgets/quran_font_button.dart';
import '../widgets/quran_font_settings_sheet.dart';
import 'surah_reading_view.dart';

/// The Surah Reading screen (spec.md User Story 2) — reached by a push
/// (`AppRoutes.surahReading`), not a tab, with the tapped Surah's number
/// passed via `RouteSettings.arguments` (research.md R11).
class SurahReadingPage extends StatelessWidget {
  const SurahReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final surahNumber = ModalRoute.of(context)!.settings.arguments as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => SurahReadingCubit(repository: QuranRepositoryImpl())
        ..loadSurah(surahNumber),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: AppBar(
          centerTitle: true,
          title: BlocBuilder<SurahReadingCubit, SurahReadingState>(
            builder: (context, state) => state is SurahReadingLoadedState
                ? _SurahReadingTitle(surah: state.surah)
                : const SizedBox.shrink(),
          ),
          actions: [
            QuranFontButton(
              onTap: () => QuranFontSettingsSheet.show(context),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(child: SurahReadingView(surahNumber: surahNumber)),
      ),
    );
  }
}

class _SurahReadingTitle extends StatelessWidget {
  const _SurahReadingTitle({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final revelationLabel = translator.word(
      surah.revelationType == RevelationType.meccan
          ? TranslationKeys.quranRevelationMeccan
          : TranslationKeys.quranRevelationMedinan,
    );
    final ayahCountLabel =
        '${surah.ayahCount} ${translator.word(TranslationKeys.quranAyahCountSuffix)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          surah.arabicName,
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        Text(
          '$revelationLabel · $ayahCountLabel',
          style: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 10.5,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
