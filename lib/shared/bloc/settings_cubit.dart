import 'package:sakinah/configurations/app_persistence_data_keys.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<AppStates> {
  SettingsCubit._internal() : super(InitialState());
  static SettingsCubit instance = SettingsCubit._internal();
  //========================================
  //======================================== Variables
  //========================================
  bool isDarkMode = false;
  Locale locale = Locale('ar');
  //========================================
  //======================================== Functions
  //========================================
  void toggleDarkMode() async {
    isDarkMode = !isDarkMode;
    // TODO: save the value in shared preferences
    emit(LoadedState(isDarkMode));
  }

  void toggleLocale() async {
    if (locale.languageCode == 'en') {
      locale = Locale('ar');
    } else {
      locale = Locale('en');
    }
    // TODO: save the value in shared preferences
    emit(LoadedState(locale));
  }

  /// Explicit language selection (specs/006-settings-screen FR-008–FR-011),
  /// unlike [toggleLocale]'s blind flip — the language bottom sheet always
  /// knows exactly which of the two supported locales the user picked.
  Future<void> setLocale(Locale newLocale) async {
    locale = newLocale;
    await SharedPrefHandler.instance!
        .save(AppPersistenceDataKeys.appLocale, value: newLocale.languageCode);
    emit(LoadedState(locale));
  }

  /// Startup hydration — called once from `main()`, after
  /// `SharedPrefHandler.init()` and before `runApp`, alongside
  /// `QuranFontSettingsCubit.instance.load()`. Does not emit: this runs
  /// before the widget tree (and therefore any listener) exists.
  Future<void> loadPersistedSettings() async {
    final prefs = SharedPrefHandler.instance!;
    if (prefs.contains(AppPersistenceDataKeys.appLocale)) {
      locale = Locale(prefs.get<String>(key: AppPersistenceDataKeys.appLocale));
    }
  }
}
