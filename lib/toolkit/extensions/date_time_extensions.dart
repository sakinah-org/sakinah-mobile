import 'package:flutter/widgets.dart' show Locale;
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Time-of-day bucket driving the Home greeting ("Good morning/afternoon/evening").
enum GreetingPeriod { morning, afternoon, evening }

extension DateTimeExtensions on DateTime {
  bool isBefore(DateTime other) => compareTo(other) == -1;
  bool isAfter(DateTime other) => compareTo(other) == 1;
  String toDateString() => "$day/$month/$year";
  String toTimeString() => "$hour:$minute:$second";
  String toDateTimeString() => "$year-$month-$day $hour:$minute:$second";
  String get getTimeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // For anything older than a week
    return '$day/$month/$year';
  }

  /// Localized day-of-week name ("Wednesday" / "الأربعاء").
  String dayNameLabel(Locale locale) =>
      DateFormat.EEEE(locale.languageCode).format(this);

  /// Hijri calendar date label ("9 Safar 1448 AH" / "٩ صفر ١٤٤٨ هـ").
  /// Computed client-side (independent of any prayer-times API response) —
  /// see specs/002-home-page/research.md §7.
  String hijriDateLabel(Locale locale) {
    final isArabic = locale.languageCode == 'ar';
    HijriCalendar.setLocal(isArabic ? 'ar' : 'en');
    final hijri = HijriCalendar.fromDate(this);
    final datePart = hijri.toFormat('dd MMMM yyyy');
    return isArabic ? '$datePart هـ' : '$datePart AH';
  }

  /// Time-of-day bucket for the Home greeting.
  GreetingPeriod get greetingPeriod {
    if (hour < 12) return GreetingPeriod.morning;
    if (hour < 17) return GreetingPeriod.afternoon;
    return GreetingPeriod.evening;
  }
}
