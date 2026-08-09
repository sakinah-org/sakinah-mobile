import '../../../configurations/app_translation_keys.dart';
import '../../../handlers/translation_handler.dart';
import '../../../utils/assets/app_icons_keys.dart';

/// Localized label + icon for a `PRAYERS.code` value
/// (`fajr|dhuhr|asr|maghrib|isha`) — shared by [PrayerTimesCard] and
/// [PrayerDayStrip] so the mapping lives in one place.
String prayerCodeLabel(String code) {
  switch (code) {
    case 'fajr':
      return translator.word(TranslationKeys.homePrayerFajr);
    case 'dhuhr':
      return translator.word(TranslationKeys.homePrayerDhuhr);
    case 'asr':
      return translator.word(TranslationKeys.homePrayerAsr);
    case 'maghrib':
      return translator.word(TranslationKeys.homePrayerMaghrib);
    case 'isha':
      return translator.word(TranslationKeys.homePrayerIsha);
    default:
      return code;
  }
}

String prayerCodeIcon(String code) {
  switch (code) {
    case 'fajr':
      return AppIcons.fajr;
    case 'dhuhr':
      return AppIcons.dhuhr;
    case 'asr':
      return AppIcons.asr;
    case 'maghrib':
      return AppIcons.maghrib;
    case 'isha':
      return AppIcons.isha;
    default:
      return AppIcons.clock;
  }
}
