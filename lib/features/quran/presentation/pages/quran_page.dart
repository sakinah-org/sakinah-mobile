import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../bloc/quran_cubit.dart';
import '../widgets/quran_font_button.dart';
import '../widgets/quran_font_settings_sheet.dart';
import 'quran_view.dart';

/// The Quran tab (spec.md User Story 1) — Surah/Juz browsing, search, and
/// the font-settings entry point. Reached directly as a `PageView` child of
/// `MainPage`, not via a named route (research.md R11).
class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) =>
          QuranCubit(repository: QuranRepositoryImpl())..loadSurahs(),
      child: Scaffold(
        appBar: AppBar(
          leading: SizedBox(),
          leadingWidth: 0,
          title: Text(translator.word(TranslationKeys.quranScreenTitle)),
          actions: [
            QuranFontButton(
              onTap: () => QuranFontSettingsSheet.show(context),
            ),
            const SizedBox(width: 16),
          ],
        ),
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: const SafeArea(child: QuranView()),
      ),
    );
  }
}
