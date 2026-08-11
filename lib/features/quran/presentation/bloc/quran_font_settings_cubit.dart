import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/bloc/session_cubit.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/quran_font_setting.dart';
import '../../domain/repositories/quran_repository.dart';
import 'quran_font_settings_state.dart';

/// Singleton (`.instance`), scoped to `lib/features/quran/` rather than
/// promoted to `lib/shared/` — nothing outside this feature reads it
/// (research.md R5). Provided once, high enough that both `QuranPage` and
/// `SurahReadingPage` see the same live instance. See
/// contracts/quran_font_settings_contract.md.
class QuranFontSettingsCubit extends Cubit<QuranFontSettingsState> {
  QuranFontSettingsCubit._internal({QuranRepository? repository})
      : _repository = repository ?? QuranRepositoryImpl(),
        super(QuranFontSettingsLoadedState(
          fontFamily: QuranFontSetting.defaults.fontFamily,
          fontSize: QuranFontSetting.defaults.fontSize,
        ));

  static QuranFontSettingsCubit instance = QuranFontSettingsCubit._internal();

  /// Test-only seam for injecting a fake [QuranRepository] — the private
  /// constructor keeps `.instance` as the real singleton for production
  /// callers, per Principle II's "static instance" pattern.
  @visibleForTesting
  factory QuranFontSettingsCubit.test(QuranRepository repository) =>
      QuranFontSettingsCubit._internal(repository: repository);

  final QuranRepository _repository;

  Future<void> load() async {
    final local = await _repository.getFontSetting();
    emit(QuranFontSettingsLoadedState(
      fontFamily: local.fontFamily,
      fontSize: local.fontSize,
    ));

    final userId = SessionCubit.instance.currentUser?.id;
    if (userId == null) return;

    final remote = await _repository.fetchRemoteFontSetting(userId);
    if (remote != null) {
      emit(QuranFontSettingsLoadedState(
        fontFamily: remote.fontFamily,
        fontSize: remote.fontSize,
      ));
    }
  }

  Future<void> setFontFamily(String fontFamily) async {
    final updated = (state as QuranFontSettingsLoadedState)
        .copyWith(fontFamily: fontFamily);
    emit(updated);
    await _persist(updated);
  }

  Future<void> setFontSize(double fontSize) async {
    final updated =
        (state as QuranFontSettingsLoadedState).copyWith(fontSize: fontSize);
    emit(updated);
    await _persist(updated);
  }

  Future<void> _persist(QuranFontSettingsLoadedState state) async {
    await _repository.saveFontSetting(
      QuranFontSetting(fontFamily: state.fontFamily, fontSize: state.fontSize),
      userId: SessionCubit.instance.currentUser?.id,
    );
  }
}
