import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/prayer_times/domain/entities/calculation_method.dart';
import '../../../../shared/prayer_times/domain/entities/prayer_location.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../toolkit/extensions/date_time_extensions.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Location card (specs/003-prayers-times-screen FR-001): city/country,
/// calculation method, and Hijri date. City/country and calculation method
/// are fetched once via [PrayerTimesCubit.loadLocationCardInfo] (never via
/// [PrayerTimesRepository] directly — see that cubit's own contract); the
/// Hijri date is computed client-side and rendered independently so it
/// degrades gracefully on its own (acceptance scenario 5).
class PrayerLocationCard extends StatefulWidget {
  const PrayerLocationCard({super.key});

  @override
  State<PrayerLocationCard> createState() => _PrayerLocationCardState();
}

class _PrayerLocationCardState extends State<PrayerLocationCard> {
  late final Future<
      ({ResolvedLocationLabel? locationLabel, CalculationMethod method})> _info;

  @override
  void initState() {
    super.initState();
    _info = PrayerTimesCubit.instance.loadLocationCardInfo();
  }

  String _methodLabel(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.ummAlQura:
        return 'Umm Al-Qura';
      case CalculationMethod.isna:
        return 'ISNA';
      case CalculationMethod.mwl:
        return 'Muslim World League';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkBrandPrimaryMedium
        : AppColors.lightBrandPrimaryMedium;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    const textPrimary = Colors.white;
    const textSecondary = Colors.white;
    const brandPrimary = Colors.white;
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: FutureBuilder<
          ({ResolvedLocationLabel? locationLabel, CalculationMethod method})>(
        future: _info,
        builder: (context, snapshot) {
          final locationLabel = snapshot.data?.locationLabel;
          final method = snapshot.data?.method;
          final locationText = locationLabel == null
              ? null
              : (locationLabel.country.isEmpty
                  ? locationLabel.city
                  : '${locationLabel.city}, ${locationLabel.country}');

          return Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,
                children: [
                  drawSvgIcon(
                    AppIcons.location,
                    width: 20,
                    height: 20,
                    iconColor: brandPrimary,
                  ),
                  Expanded(
                    child: Text(
                      locationText ?? '—',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              // Rendered independently of the location fetch above so the
              // Hijri date degrades gracefully on its own (FR-001 scenario 5).
              Builder(
                builder: (context) {
                  try {
                    return Row(
                      children: [
                        if (method != null)
                          Expanded(
                            child: Text(
                              '${translator.word(TranslationKeys.prayersLocationCalculationMethodLabel)}: ${_methodLabel(method)}',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFontFamily,
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        Text(
                          now.hijriDateLabel(locale),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFontFamily,
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
