import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/app_routes.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../shared/widgets/shimmer_container.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../bloc/quran_cubit.dart';
import '../bloc/quran_state.dart';
import '../widgets/juz_section_header.dart';
import '../widgets/quran_search_empty_view.dart';
import '../widgets/quran_search_field.dart';
import '../widgets/quran_tab_switcher.dart';
import '../widgets/quran_unavailable_view.dart';
import '../widgets/surah_list_tile.dart';

/// Scroll body of [QuranPage] — search field, Surah/Juz tabs, and search
/// results (spec.md User Stories 1, 3, 4).
class QuranView extends StatefulWidget {
  const QuranView({super.key});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<QuranCubit>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        return switch (state) {
          QuranInitialState() || QuranLoadingState() => ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ShimmerContainer(height: 64, borderRadius: 14),
                SizedBox(height: 8),
                ShimmerContainer(height: 64, borderRadius: 14),
                SizedBox(height: 8),
                ShimmerContainer(height: 64, borderRadius: 14),
              ],
            ),
          QuranUnavailableState() => QuranUnavailableView(
              onRetry: () => context.read<QuranCubit>().loadSurahs(),
            ),
          QuranLoadedState() => _QuranLoadedBody(
              state: state,
              searchController: _searchController,
              onClearSearch: _clearSearch,
            ),
        };
      },
    );
  }
}

class _QuranLoadedBody extends StatelessWidget {
  const _QuranLoadedBody({
    required this.state,
    required this.searchController,
    required this.onClearSearch,
  });

  final QuranLoadedState state;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  void _openSurah(BuildContext context, int surahNumber) {
    Navigator.pushNamed(context, AppRoutes.surahReading,
        arguments: surahNumber);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    final isSearching = state.searchQuery != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    Widget body;
    if (isSearching) {
      final results = state.searchResults ?? const [];
      body = results.isEmpty
          ? const QuranSearchEmptyView()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final surah in results)
                  SurahListTile(
                    surah: surah,
                    onTap: () => _openSurah(context, surah.number),
                  ),
              ],
            );
    } else {
      final items = <Widget>[];
      if (state.activeTab == QuranTab.surah) {
        for (final surah in state.surahs) {
          items.add(SurahListTile(
            surah: surah,
            onTap: () => _openSurah(context, surah.number),
          ));
        }
      } else {
        for (final section in state.juzSections) {
          items.add(JuzSectionHeader(juzNumber: section.juzNumber));
          for (final surah in section.surahs) {
            items.add(SurahListTile(
              surah: surah,
              onTap: () => _openSurah(context, surah.number),
            ));
          }
        }
      }
      body = ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: items,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          child: Row(
            children: [
              Expanded(
                child: QuranSearchField(
                  controller: searchController,
                  onChanged: (query) =>
                      query.isEmpty ? onClearSearch() : cubit.search(query),
                ),
              ),
              if (isSearching)
                IconButton(
                  icon: drawSvgIcon(AppIcons.close,
                      width: 18, height: 18, iconColor: textTertiary),
                  onPressed: onClearSearch,
                ),
            ],
          ),
        ),
        if (!isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
            child: QuranTabSwitcher(
              activeTab: state.activeTab,
              onChanged: cubit.switchTab,
              enabled: true,
            ),
          ),
        Expanded(child: body),
      ],
    );
  }
}
