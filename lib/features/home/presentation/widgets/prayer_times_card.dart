import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/prayer_times/domain/entities/prayer_times.dart';
import '../../../../shared/prayer_times/presentation/prayer_code_presentation.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import 'prayer_times_countdown.dart';

/// Gradient "next prayer" card — matches the Home screen mock's teal card:
/// label + prayer name + edit (gear) icon on top, ticking countdown below.
class PrayerTimesCard extends StatelessWidget {
  const PrayerTimesCard({
    super.key,
    required this.times,
    required this.onEditTap,
  });

  final PrayerTimes times;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final next = times.nextPrayer(DateTime.now());
    final timeLabel = DateFormat.jm(locale.languageCode).format(next.time);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 132,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.5, -1),
            end: Alignment(0.5, 1),
            colors: [AppColors.teal700, AppColors.teal900],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translator
                                  .word(TranslationKeys.homeNextPrayerLabel),
                              style: TextStyle(
                                fontFamily: AppTypography.uiFontFamily,
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prayerCodeLabel(next.code),
                              style: const TextStyle(
                                fontFamily: AppTypography.uiFontFamily,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onEditTap,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          child: Center(
                            child: drawSvgIcon(
                              AppIcons.settingsIcon,
                              width: 17,
                              height: 17,
                              iconColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      PrayerTimesCountdown(
                        target: next.time,
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 45,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${translator.word(TranslationKeys.homeUntilAdhanLabel)} · $timeLabel',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
