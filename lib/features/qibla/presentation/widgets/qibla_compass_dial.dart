import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';
import '../../domain/entities/qibla_reading.dart';

const _dialSize = 256.0;

/// 8-point compass-rose label for a bearing (0–360, from north) — display
/// only, not itself a functional requirement, but shown in the imported
/// design mock next to the degree value.
String qiblaCompassPointLabel(double bearingDegrees) {
  const keys = [
    TranslationKeys.qiblaCompassNorth,
    TranslationKeys.qiblaCompassNortheast,
    TranslationKeys.qiblaCompassEast,
    TranslationKeys.qiblaCompassSoutheast,
    TranslationKeys.qiblaCompassSouth,
    TranslationKeys.qiblaCompassSouthwest,
    TranslationKeys.qiblaCompassWest,
    TranslationKeys.qiblaCompassNorthwest,
  ];
  final normalized = bearingDegrees % 360;
  final index = ((normalized + 22.5) / 45).floor() % 8;
  return translator.word(keys[index]);
}

/// Live rotating Qibla dial (design §10) — a fixed N/S/E/W ring with a
/// fixed center Kaaba emblem, and a needle that rotates to keep pointing at
/// the Kaaba as the device turns (FR-018).
class QiblaCompassDial extends StatelessWidget {
  const QiblaCompassDial({super.key, required this.reading});

  final QiblaLiveReading reading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final borderStrong =
        isDark ? AppColors.darkBorderStrong : AppColors.lightBorderStrong;
    final textTertiary =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    // The needle points at (bearingDegrees - headingDegrees) clockwise from
    // "up" on the screen — the Kaaba's absolute bearing minus however far
    // the device has turned away from true north.
    final rotationDegrees =
        (reading.bearingDegrees - reading.headingDegrees) % 360;
    final rotationRadians = rotationDegrees * pi / 180;

    return SizedBox(
      width: _dialSize,
      height: _dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surface,
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: CustomPaint(
              painter: _DashedCirclePainter(color: borderStrong),
              child: const SizedBox.expand(),
            ),
          ),
          const Positioned(
            top: 12,
            child: Text('N',
                style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error)),
          ),
          Positioned(
            bottom: 12,
            child: Text('S',
                style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textTertiary)),
          ),
          Positioned(
            left: 14,
            child: Text('W',
                style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textTertiary)),
          ),
          Positioned(
            right: 14,
            child: Text('E',
                style: TextStyle(
                    fontFamily: AppTypography.uiFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textTertiary)),
          ),
          Transform.rotate(
            angle: rotationRadians,
            child: SizedBox(
              width: _dialSize,
              height: _dialSize,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: CustomPaint(
                      size: const Size(18, 30),
                      painter: _NeedleTipPainter(color: brandPrimary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Container(
                      width: 3,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            brandPrimary,
                            brandPrimary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.teal700, AppColors.teal900],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal900.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: drawSvgIcon(AppIcons.qibla,
                width: 34, height: 34, iconColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const dashDegrees = 6.0;
    const gapDegrees = 6.0;
    var start = 0.0;
    while (start < 360) {
      canvas.drawArc(
          rect, start * pi / 180, dashDegrees * pi / 180, false, paint);
      start += dashDegrees + gapDegrees;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NeedleTipPainter extends CustomPainter {
  _NeedleTipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NeedleTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
