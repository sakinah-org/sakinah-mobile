import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quran_font_settings_cubit.dart';
import '../bloc/quran_font_settings_state.dart';
import '../bloc/surah_reading_cubit.dart';
import '../bloc/surah_reading_state.dart';
import '../widgets/ayah_text_view.dart';
import '../widgets/quran_unavailable_view.dart';

/// Body of [SurahReadingPage] — loading skeleton, the continuous ayat
/// (via [AyahTextView]), or the shared unable-to-load state.
class SurahReadingView extends StatelessWidget {
  const SurahReadingView({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurahReadingCubit, SurahReadingState>(
      builder: (context, state) {
        return switch (state) {
          SurahReadingInitialState() ||
          SurahReadingLoadingState() =>
            const Center(child: CircularProgressIndicator()),
          SurahReadingUnavailableState() => QuranUnavailableView(
              onRetry: () =>
                  context.read<SurahReadingCubit>().loadSurah(surahNumber),
            ),
          SurahReadingLoadedState(:final ayahs) => SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child:
                  BlocBuilder<QuranFontSettingsCubit, QuranFontSettingsState>(
                bloc: QuranFontSettingsCubit.instance,
                builder: (context, fontState) {
                  final font = fontState as QuranFontSettingsLoadedState;
                  return AyahTextView(
                    ayahs: ayahs,
                    fontFamily: font.fontFamily,
                    fontSize: font.fontSize,
                  );
                },
              ),
            ),
        };
      },
    );
  }
}
