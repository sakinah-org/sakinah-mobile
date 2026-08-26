import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_states.dart';
import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../shared/bloc/session_cubit.dart';
import '../../../../shared/bloc/settings_cubit.dart';
import '../../../../utils/assets/app_icons_keys.dart';
import '../../../../utils/style/app_colors.dart';
import '../widgets/language_bottom_sheet.dart';
import '../widgets/settings_authenticated_profile_card.dart';
import '../widgets/settings_guest_prompt_card.dart';
import '../widgets/settings_logout_confirmation_dialog.dart';
import '../widgets/settings_option_tile.dart';
import '../widgets/settings_toggle_tile.dart';

/// The Settings tab (specs/006-settings-screen) — account section + options
/// list. Reached directly as a `PageView` child of `MainPage`, not via a
/// named route (research.md R11), matching QuranPage/HomePage.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await SettingsLogoutConfirmationDialog.show(context);
    if (confirmed == true) {
      await SessionCubit.instance.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        leadingWidth: 0,
        title: Text(translator.word(TranslationKeys.settings)),
      ),
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: BlocBuilder<SessionCubit, AppStates>(
          builder: (context, sessionState) {
            final user = SessionCubit.instance.currentUser;
            final isLoggedIn = user != null;
            final locale = context.watch<SettingsCubit>().locale;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                isLoggedIn
                    ? SettingsAuthenticatedProfileCard(user: user)
                    : const SettingsGuestPromptCard(),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SettingsOptionTile(
                        icon: AppIcons.clock,
                        label: translator
                            .word(TranslationKeys.settingsPrayerTimesOption),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.prayers),
                      ),
                      Divider(height: 1, color: border),
                      SettingsOptionTile(
                        icon: AppIcons.qibla,
                        label:
                            translator.word(TranslationKeys.qiblaScreenTitle),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.qiblaCompass),
                      ),
                      Divider(height: 1, color: border),
                      SettingsOptionTile(
                        icon: AppIcons.language,
                        label: translator
                            .word(TranslationKeys.settingsChangeLanguageOption),
                        trailingValue:
                            LanguageBottomSheet.nativeName(locale.languageCode),
                        onTap: () => LanguageBottomSheet.show(context),
                      ),
                      Divider(height: 1, color: border),
                      SettingsToggleTile(
                        icon: AppIcons.appearance,
                        label: translator
                            .word(TranslationKeys.settingsDarkModeOption),
                        value: context.watch<SettingsCubit>().isDarkMode,
                        onChanged: (_) =>
                            SettingsCubit.instance.toggleDarkMode(),
                      ),
                    ],
                  ),
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 16),
                  _LogoutButton(onTap: () => _logout(context)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const error = AppColors.error;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.logout, size: 18, color: error),
        label: Text(translator.word(TranslationKeys.settingsLogoutOption)),
      ),
    );
  }
}
