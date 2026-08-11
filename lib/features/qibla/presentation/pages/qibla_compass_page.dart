import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/qibla_reading.dart';
import '../bloc/qibla_compass_cubit.dart';
import '../bloc/qibla_compass_state.dart';
import '../widgets/qibla_calibration_banner.dart';
import '../widgets/qibla_compass_dial.dart';
import '../widgets/qibla_location_required_view.dart';
import '../widgets/qibla_static_bearing_view.dart';

/// Qibla Compass screen (spec.md User Story 4, design §10) — pushed from
/// the Settings options list.
class QiblaCompassPage extends StatelessWidget {
  const QiblaCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => QiblaCompassCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(translator.word(TranslationKeys.qiblaScreenTitle)),
        ),
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: BlocBuilder<QiblaCompassCubit, QiblaCompassState>(
            builder: (context, state) {
              return switch (state) {
                QiblaInitialState() ||
                QiblaLoadingState() =>
                  const Center(child: CircularProgressIndicator()),
                QiblaLiveState(:final reading) => _LiveBody(reading: reading),
                QiblaStaticState(:final reading) => Center(
                    child: QiblaStaticBearingView(reading: reading),
                  ),
                QiblaLocationRequiredState() => Center(
                    child: QiblaLocationRequiredView(
                      onRetry: () => context.read<QiblaCompassCubit>().retry(),
                    ),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.reading});

  final QiblaLiveReading reading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    final showCalibration = reading.accuracy != CompassAccuracy.good;
    final distanceKm = reading.distanceKm;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showCalibration) ...[
            const QiblaCalibrationBanner(),
            const SizedBox(height: 20),
          ],
          QiblaCompassDial(reading: reading),
          const SizedBox(height: 26),
          Text(
            '${reading.bearingDegrees.round()}°',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${translator.word(TranslationKeys.qiblaDirectionLabel)} · '
            '${qiblaCompassPointLabel(reading.bearingDegrees)}',
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: brandPrimary,
            ),
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 8),
            Text(
              '${translator.word(TranslationKeys.qiblaDistanceToMeccaLabel)} · '
              '${distanceKm.round()} km',
              style: TextStyle(
                fontFamily: AppTypography.uiFontFamily,
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined, size: 15, color: brandPrimary),
                const SizedBox(width: 8),
                Text(
                  translator.word(TranslationKeys.qiblaAlignInstruction),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
