import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../handlers/notification_handler.dart';
import '../../../../handlers/permission_handler.dart';
import '../../../../shared/bloc/session_cubit.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_state.dart';
import '../../data/repositories/prayer_notification_settings_repository_impl.dart';
import '../../domain/entities/prayer_reminder_setting.dart';
import '../../domain/repositories/prayer_notification_settings_repository.dart';
import 'prayer_notification_settings_state.dart';

/// Feature-scoped (NOT a singleton, unlike [PrayerTimesCubit]) — provided
/// via `BlocProvider` at `PrayersPage` only. See
/// contracts/prayer_notification_settings_cubit_contract.md.
class PrayerNotificationSettingsCubit
    extends Cubit<PrayerNotificationSettingsState> {
  PrayerNotificationSettingsCubit({
    PrayerNotificationSettingsRepository? repository,
    PermissionHandler? permissionHandler,
    NotificationHandler? notificationHandler,
  })  : _repository = repository ?? PrayerNotificationSettingsRepositoryImpl(),
        _permissionHandler = permissionHandler ?? PermissionHandler(),
        _notificationHandler =
            notificationHandler ?? NotificationHandler.instance,
        super(const PrayerNotificationSettingsInitialState());

  final PrayerNotificationSettingsRepository _repository;
  final PermissionHandler _permissionHandler;
  final NotificationHandler _notificationHandler;

  Future<void> loadSettings() async {
    emit(const PrayerNotificationSettingsLoadingState());

    final userId = SessionCubit.instance.currentUser?.id;
    final settings = userId != null
        ? await _repository.reconcileWithRemote(userId: userId)
        : await _repository.getLocalSettings();

    final permissionStatus = await _resolvePermissionStatus();
    await _rescheduleAll(settings);

    emit(PrayerNotificationSettingsLoadedState(settings,
        permissionStatus: permissionStatus));
  }

  Future<void> toggle(String prayerCode, bool isEnabled) async {
    final current = state;
    if (current is! PrayerNotificationSettingsLoadedState) return;

    final now = DateTime.now();
    PrayerReminderSetting? changed;
    final updated = [
      for (final setting in current.settings)
        if (setting.prayerCode == prayerCode)
          (changed = setting.copyWith(isEnabled: isEnabled, updatedAt: now))
        else
          setting,
    ];
    if (changed == null) return;

    // Optimistic UI update first (FR-002 acceptance scenario 2/3).
    emit(PrayerNotificationSettingsLoadedState(updated,
        permissionStatus: current.permissionStatus));

    await _repository.saveLocalSetting(changed);


    final time = _currentTimesByCode()?[prayerCode];
    if (isEnabled && time != null) {
      await _notificationHandler.scheduleReminder(
          prayerCode: prayerCode, prayerTime: time);
    } else if (!isEnabled) {
      await _notificationHandler.cancelReminder(prayerCode: prayerCode);
    }

    final userId = SessionCubit.instance.currentUser?.id;
    if (userId != null) {
      unawaited(_repository.syncToRemote(changed, userId: userId));
    }
  }

  /// FR-012 (first visit) — also harmlessly re-attempted on later loads
  /// (matches `PermissionHandler`'s existing auto-retry-while-denied
  /// convention used by every other permission check in this codebase).
  Future<void> requestNotificationPermission() async {
    final status = await _resolvePermissionStatus();
    _emitPermissionStatus(status);
  }

  /// FR-013/FR-014 "Enable" control — opens device notification settings.
  Future<void> openNotificationSettings() =>
      _permissionHandler.openAppNotificationSettings();

  /// Re-checks permission only (not a full reconcile) — called on app
  /// resume so returning from device settings reflects immediately
  /// (contract: "permission re-check on resume").
  Future<void> refreshPermissionStatus() async {
    final status = await _resolvePermissionStatus();
    _emitPermissionStatus(status);
  }

  void _emitPermissionStatus(NotificationPermissionStatus status) {
    final current = state;
    if (current is PrayerNotificationSettingsLoadedState) {
      emit(PrayerNotificationSettingsLoadedState(current.settings,
          permissionStatus: status));
    }
  }

  Future<NotificationPermissionStatus> _resolvePermissionStatus() async {
    final raw = await _permissionHandler.checkNotificationPermissionStatus();
    switch (raw) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
      case ph.PermissionStatus.provisional:
        return NotificationPermissionStatus.granted;
      case ph.PermissionStatus.permanentlyDenied:
      case ph.PermissionStatus.restricted:
        return NotificationPermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.denied:
        return NotificationPermissionStatus.denied;
    }
  }

  /// Reads [PrayerTimesCubit.instance] directly (never refetches) — per
  /// that cubit's own "only caller of PrayerTimesRepository" contract, this
  /// class only consumes its already-loaded state.
  Map<String, DateTime>? _currentTimesByCode() {
    final ptState = PrayerTimesCubit.instance.state;
    if (ptState is! PrayerTimesLoadedState) return null;
    final times = ptState.times;
    return {
      'fajr': times.fajr,
      'dhuhr': times.dhuhr,
      'asr': times.asr,
      'maghrib': times.maghrib,
      'isha': times.isha,
    };
  }

  Future<void> _rescheduleAll(List<PrayerReminderSetting> settings) async {
    final times = _currentTimesByCode();
    if (times == null) return; // nothing to schedule against yet
    await _notificationHandler.rescheduleAll(
      [
        for (final setting in settings)
          (prayerCode: setting.prayerCode, isEnabled: setting.isEnabled),
      ],
      times,
    );
  }
}
