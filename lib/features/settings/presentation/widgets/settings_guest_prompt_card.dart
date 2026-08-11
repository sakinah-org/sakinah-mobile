import 'package:flutter/material.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../shared/widgets/icon_handler.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../../../../utils/style/app_typography.dart';

/// Guest-state account section (spec.md FR-002) — matches the imported
/// design mock's §08 GUEST hero card: teal gradient, decorative circle,
/// person icon, and a CTA into the existing sign-in flow.
class SettingsGuestPromptCard extends StatelessWidget {
  const SettingsGuestPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              left: -24,
              bottom: -24,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: Center(
                      child: drawSvgIcon(
                        AppIcons.profile,
                        width: 28,
                        height: 28,
                        iconColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translator.word(TranslationKeys.settingsGuestTitle),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    translator.word(TranslationKeys.authLoginSubtitle),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFontFamily,
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.teal900,
                        textStyle: const TextStyle(
                          fontFamily: AppTypography.uiFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          Text(translator.word(TranslationKeys.authLoginCta)),
                    ),
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
