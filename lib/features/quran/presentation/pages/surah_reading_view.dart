import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/mushaf_page.dart';
import '../bloc/quran_font_settings_cubit.dart';
import '../bloc/quran_font_settings_state.dart';
import '../bloc/surah_reading_cubit.dart';
import '../bloc/surah_reading_state.dart';
import '../widgets/mushaf_page_view.dart';
import '../widgets/quran_unavailable_view.dart';

/// Body of [SurahReadingPage] — loading skeleton, the paged Mushaf reader
/// (specs/009-quran-paged-reading), or the shared unable-to-load state.
class SurahReadingView extends StatelessWidget {
  const SurahReadingView({
    super.key,
    required this.surahNumber,
    required this.pageController,
    required this.onPageChanged,
  });

  final int surahNumber;

  /// Only used once [SurahReadingState] is [SurahReadingLoadedState] — null
  /// during Loading/Unavailable, when this widget never builds a `PageView`
  /// anyway (the owning [SurahReadingPage] only constructs the controller
  /// once it knows the correct `initialPage`).
  final PageController? pageController;
  final ValueChanged<int> onPageChanged;

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
                  context.read<SurahReadingCubit>().initialize(surahNumber),
            ),
          SurahReadingLoadedState(:final totalPages) =>
            BlocBuilder<QuranFontSettingsCubit, QuranFontSettingsState>(
              bloc: QuranFontSettingsCubit.instance,
              builder: (context, fontState) {
                final font = fontState as QuranFontSettingsLoadedState;
                final repository = context.read<SurahReadingCubit>().repository;
                return PageView.builder(
                  controller: pageController!,
                  itemCount: totalPages,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) => onPageChanged(index + 1),
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    return FutureBuilder<MushafPage>(
                      future: repository.getPage(pageNumber),
                      builder: (context, snapshot) {
                        final page = snapshot.data;
                        if (page == null) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return MushafPageView(
                          page: page,
                          fontFamily: font.fontFamily,
                          fontSize: font.fontSize,
                        );
                      },
                    );
                  },
                );
              },
            ),
        };
      },
    );
  }
}
