import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/app_routes.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../utils/style/app_colors.dart';
import '../bloc/ayah_of_today_cubit.dart';
import '../widgets/ayah_of_today_section.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/prayer_times_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AyahOfTodayCubit _ayahCubit;

  @override
  void initState() {
    super.initState();
    PrayerTimesCubit.instance.loadPrayerTimes();
    _ayahCubit = AyahOfTodayCubit()..loadAyahOfToday();
  }

  @override
  void dispose() {
    _ayahCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider.value(
      value: _ayahCubit,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const HomeTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeGreetingHeader(),
                      const SizedBox(height: 13),
                      PrayerTimesSection(
                        onEditTap: () =>
                            Navigator.pushNamed(context, AppRoutes.prayers),
                      ),
                      const SizedBox(height: 13),
                      const AyahOfTodaySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
