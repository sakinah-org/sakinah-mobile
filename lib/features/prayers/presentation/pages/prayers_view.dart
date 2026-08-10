import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_state.dart';
import '../../../../shared/prayer_times/presentation/prayer_times_unavailable_view.dart';
import '../../../../shared/widgets/shimmer_container.dart';
import '../../domain/entities/prayer_reminder_setting.dart';
import '../bloc/prayer_notification_settings_cubit.dart';
import '../bloc/prayer_notification_settings_state.dart';
import '../widgets/notification_permission_help_card.dart';
import '../widgets/notification_permission_permanently_denied_card.dart';
import '../widgets/prayer_location_card.dart';
import '../widgets/prayer_reminder_tile.dart';
import '../widgets/prayer_reminders_off_banner.dart';

/// Scroll body of [PrayersPage] — composes [PrayerTimesCubit] (times +
/// location, unchanged/shared) with [PrayerNotificationSettingsCubit]
/// (toggles, permission, all-off banner) into one list.
class PrayersView extends StatelessWidget {
  const PrayersView({super.key});

  static const _order = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      bloc: PrayerTimesCubit.instance,
      builder: (context, ptState) {
        return BlocBuilder<PrayerNotificationSettingsCubit,
            PrayerNotificationSettingsState>(
          builder: (context, pnState) {
            final stillLoading = ptState is PrayerTimesInitialState ||
                ptState is PrayerTimesLoadingState ||
                pnState is PrayerNotificationSettingsInitialState ||
                pnState is PrayerNotificationSettingsLoadingState;

            if (stillLoading) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ShimmerContainer(height: 64, borderRadius: 16),
                  SizedBox(height: 12),
                  ShimmerContainer(height: 300, borderRadius: 14),
                ],
              );
            }

            final children = <Widget>[];
            final loadedNotifications =
                pnState is PrayerNotificationSettingsLoadedState
                    ? pnState
                    : null;

            if (loadedNotifications != null) {
              switch (loadedNotifications.permissionStatus) {
                case NotificationPermissionStatus.denied:
                  children.add(NotificationPermissionHelpCard(
                    onEnable: () => context
                        .read<PrayerNotificationSettingsCubit>()
                        .requestNotificationPermission(),
                  ));
                case NotificationPermissionStatus.permanentlyDenied:
                  children.add(NotificationPermissionPermanentlyDeniedCard(
                    onEnable: () => context
                        .read<PrayerNotificationSettingsCubit>()
                        .openNotificationSettings(),
                  ));
                case NotificationPermissionStatus.granted:
                case NotificationPermissionStatus.notDetermined:
                  break;
              }
              // Not shown alongside the permanently-denied card — toggles are
              // already inert/unreadable in that state (spec.md Edge Cases).
              if (loadedNotifications.allRemindersOff &&
                  loadedNotifications.permissionStatus !=
                      NotificationPermissionStatus.permanentlyDenied) {
                children.add(const PrayerRemindersOffBanner());
              }
            }

            switch (ptState) {
              case PrayerTimesLoadedState(:final times):
                final timesByCode = {
                  'fajr': times.fajr,
                  'dhuhr': times.dhuhr,
                  'asr': times.asr,
                  'maghrib': times.maghrib,
                  'isha': times.isha,
                };
                final settingsByCode = <String, PrayerReminderSetting>{
                  if (loadedNotifications != null)
                    for (final s in loadedNotifications.settings)
                      s.prayerCode: s,
                };
                final interactive = loadedNotifications != null &&
                    loadedNotifications.permissionStatus ==
                        NotificationPermissionStatus.granted;

                children
                  ..add(const PrayerLocationCard())
                  ..add(const SizedBox(height: 16));
                for (final code in _order) {
                  final setting = settingsByCode[code];
                  children.add(PrayerReminderTile(
                    code: code,
                    time: timesByCode[code]!,
                    isEnabled: setting?.isEnabled ?? true,
                    onToggle: interactive
                        ? (value) => context
                            .read<PrayerNotificationSettingsCubit>()
                            .toggle(code, value)
                        : null,
                  ));
                }
              case PrayerTimesLocationRequiredState():
                children.add(PrayerTimesUnavailableView(
                  variant: PrayerTimesUnavailableVariant.locationRequired,
                  onRetry: () => PrayerTimesCubit.instance.refreshLocation(),
                ));
              case PrayerTimesUnavailableState():
                children.add(PrayerTimesUnavailableView(
                  variant: PrayerTimesUnavailableVariant.unableToLoad,
                  onRetry: () => PrayerTimesCubit.instance.loadPrayerTimes(),
                ));
              case PrayerTimesInitialState():
              case PrayerTimesLoadingState():
                break; // unreachable — covered by stillLoading above
            }

            return ListView(
                padding: const EdgeInsets.all(16), children: children);
          },
        );
      },
    );
  }
}
