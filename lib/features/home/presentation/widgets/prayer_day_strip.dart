import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/prayer_times/domain/entities/prayer_times.dart';
import '../../../../shared/prayer_times/presentation/prayer_code_presentation.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// 5-prayer condensed row — the next prayer is visually emphasized
/// (filled brand-primary chip) per the Home screen mock.
class PrayerDayStrip extends StatelessWidget {
  const PrayerDayStrip({super.key, required this.times});

  final PrayerTimes times;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final next = times.nextPrayer(DateTime.now());
    final entries = [
      MapEntry('fajr', times.fajr),
      MapEntry('dhuhr', times.dhuhr),
      MapEntry('asr', times.asr),
      MapEntry('maghrib', times.maghrib),
      MapEntry('isha', times.isha),
    ];

    return Row(
      children: [
        for (final entry in entries) ...[
          Expanded(
            child: _PrayerChip(
              code: entry.key,
              time: entry.value,
              locale: locale,
              isNext: entry.key == next.code,
            ),
          ),
          if (entry.key != entries.last.key) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({
    required this.code,
    required this.time,
    required this.locale,
    required this.isNext,
  });

  final String code;
  final DateTime time;
  final Locale locale;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final onBrand = isDark ? AppColors.darkOnBrand : AppColors.lightOnBrand;

    final iconColor = isNext ? onBrand.withValues(alpha: 0.9) : textSecondary;
    final labelColor = isNext ? onBrand.withValues(alpha: 0.92) : textSecondary;
    final timeColor = isNext ? onBrand : textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: BoxDecoration(
        color: isNext ? brandPrimary : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNext ? brandPrimary : border),
      ),
      child: Column(
        children: [
          drawSvgIcon(prayerCodeIcon(code),
              width: 18, height: 18, iconColor: iconColor),
          const SizedBox(height: 5),
          Text(
            prayerCodeLabel(code),
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 10,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat.jm(locale.languageCode).format(time),
            style: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 12,
              fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }
}
