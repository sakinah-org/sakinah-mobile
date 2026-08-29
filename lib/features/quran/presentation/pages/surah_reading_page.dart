import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/surah.dart';
import '../bloc/surah_reading_cubit.dart';
import '../bloc/surah_reading_state.dart';
import '../widgets/quran_font_button.dart';
import '../widgets/quran_font_settings_sheet.dart';
import '../widgets/quran_page_jump_sheet.dart';
import '../widgets/quran_reading_actions_bar.dart';
import 'surah_reading_view.dart';

/// The Surah Reading screen (spec.md User Story 2) — reached by a push
/// (`AppRoutes.surahReading`), not a tab, with the tapped Surah's number
/// passed via `RouteSettings.arguments` (research.md R11). Owns the
/// `PageController` (specs/009-quran-paged-reading) so both the app-bar
/// title and the paged body ([SurahReadingView]) can share it. The app-bar
/// title tracks the *currently visible page's* Surah (research.md R3) via
/// [_currentPageNumber], not just the originally tapped Surah.
class SurahReadingPage extends StatefulWidget {
  const SurahReadingPage({super.key});

  @override
  State<SurahReadingPage> createState() => _SurahReadingPageState();
}

class _SurahReadingPageState extends State<SurahReadingPage> {
  late final SurahReadingCubit _cubit;
  PageController? _pageController;
  int? _surahNumber;
  final ValueNotifier<int?> _currentPageNumber = ValueNotifier(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_surahNumber == null) {
      _surahNumber = ModalRoute.of(context)!.settings.arguments as int;
      _cubit = SurahReadingCubit(repository: QuranRepositoryImpl())
        ..initialize(_surahNumber!);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _currentPageNumber.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onPageChanged(int pageNumber) => _currentPageNumber.value = pageNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        appBar: AppBar(
          centerTitle: true,
          title: BlocBuilder<SurahReadingCubit, SurahReadingState>(
            builder: (context, state) {
              if (state is! SurahReadingLoadedState) {
                return const SizedBox.shrink();
              }
              return ValueListenableBuilder<int?>(
                valueListenable: _currentPageNumber,
                builder: (context, currentPageNumber, _) {
                  final pageNumber =
                      currentPageNumber ?? state.startingPageNumber;
                  return FutureBuilder<MushafPage>(
                    future: _cubit.repository.getPage(pageNumber),
                    builder: (context, snapshot) {
                      final page = snapshot.data;
                      if (page == null) return const SizedBox.shrink();
                      return _SurahReadingTitle(surah: page.startSurah);
                    },
                  );
                },
              );
            },
          ),
          actions: [
            _AppBarIconButton(
              icon: AppIcons.audioDownload,
              tooltip:
                  translator.word(TranslationKeys.quranAudioDownloadTooltip),
              // No-op this phase (spec.md Assumptions) — no audio feature
              // exists yet to trigger.
              onTap: () {},
            ),
            const SizedBox(width: 8),
            BlocBuilder<SurahReadingCubit, SurahReadingState>(
              builder: (context, state) {
                final totalPages =
                    state is SurahReadingLoadedState ? state.totalPages : null;
                return _AppBarIconButton(
                  icon: AppIcons.pageJump,
                  tooltip: translator.word(TranslationKeys.quranJumpSheetTitle),
                  onTap: totalPages == null || _pageController == null
                      ? null
                      : () => QuranPageJumpSheet.show(
                            context,
                            totalPages: totalPages,
                            onJumpToPage: (page) =>
                                _pageController!.jumpToPage(page - 1),
                          ),
                );
              },
            ),
            const SizedBox(width: 8),
            QuranFontButton(
              onTap: () => QuranFontSettingsSheet.show(context),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<SurahReadingCubit, SurahReadingState>(
                  builder: (context, state) {
                    if (state is SurahReadingLoadedState) {
                      _pageController ??= PageController(
                        initialPage: state.startingPageNumber - 1,
                      );
                    }
                    return SurahReadingView(
                      surahNumber: _surahNumber!,
                      pageController: _pageController,
                      onPageChanged: _onPageChanged,
                    );
                  },
                ),
              ),
              const QuranReadingActionsBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-bar action button matching [QuranFontButton]'s square, bordered
/// style, but for an SVG icon instead of the "Aa" glyph. `onTap: null`
/// renders a visibly disabled (dimmed) state — used while the page total
/// isn't known yet.
class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final String icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: drawSvgIcon(icon,
                width: 18, height: 18, iconColor: brandPrimary),
          ),
        ),
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
