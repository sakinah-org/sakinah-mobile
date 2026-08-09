import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_state.dart';
import '../../../../shared/widgets/shimmer_container.dart';
import 'prayer_day_strip.dart';
import 'prayer_times_card.dart';
import 'prayer_times_unavailable_view.dart';

/// Subscribes to the global [PrayerTimesCubit] and renders whichever of the
/// 5 states it's currently in — keeps `HomePage` itself to pure composition.
class PrayerTimesSection extends StatelessWidget {
  const PrayerTimesSection({super.key, required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      bloc: PrayerTimesCubit.instance,
      builder: (context, state) {
        switch (state) {
          case PrayerTimesInitialState():
          case PrayerTimesLoadingState():
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShimmerContainer(height: 130, borderRadius: 16),
                SizedBox(height: 8),
                ShimmerContainer(height: 76, borderRadius: 12),
              ],
            );
          case PrayerTimesLoadedState(:final times):
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrayerTimesCard(times: times, onEditTap: onEditTap),
                const SizedBox(height: 8),
                PrayerDayStrip(times: times),
              ],
            );
          case PrayerTimesLocationRequiredState():
            return PrayerTimesUnavailableView(
              variant: PrayerTimesUnavailableVariant.locationRequired,
              onRetry: () => PrayerTimesCubit.instance.refreshLocation(),
            );
          case PrayerTimesUnavailableState():
            return PrayerTimesUnavailableView(
              variant: PrayerTimesUnavailableVariant.unableToLoad,
              onRetry: () => PrayerTimesCubit.instance.loadPrayerTimes(),
            );
        }
      },
    );
  }
}
