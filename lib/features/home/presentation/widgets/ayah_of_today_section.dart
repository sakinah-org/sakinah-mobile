import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/shimmer_container.dart';
import '../bloc/ayah_of_today_cubit.dart';
import '../bloc/ayah_of_today_state.dart';
import 'ayah_of_today_card.dart';
import 'ayah_of_today_unavailable_view.dart';

/// Subscribes to the Home-scoped [AyahOfTodayCubit] and renders whichever
/// of the 4 states it's currently in.
class AyahOfTodaySection extends StatelessWidget {
  const AyahOfTodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AyahOfTodayCubit, AyahOfTodayState>(
      builder: (context, state) {
        switch (state) {
          case AyahOfTodayInitialState():
          case AyahOfTodayLoadingState():
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShimmerContainer(height: 20, borderRadius: 6),
                SizedBox(height: 12),
                ShimmerContainer(height: 160, borderRadius: 16),
              ],
            );
          case AyahOfTodayLoadedState(:final ayah, :final isFromToday):
            return AyahOfTodayCard(ayah: ayah, isFromToday: isFromToday);
          case AyahOfTodayUnavailableState():
            return AyahOfTodayUnavailableView(
              onRetry: () => context.read<AyahOfTodayCubit>().retry(),
            );
        }
      },
    );
  }
}
