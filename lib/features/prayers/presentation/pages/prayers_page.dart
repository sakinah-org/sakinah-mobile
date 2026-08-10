import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
import '../../../../shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../../utils/style/app_colors.dart';
import '../bloc/prayer_notification_settings_cubit.dart';
import 'prayers_view.dart';

/// Real Prayers Times screen (specs/003-prayers-times-screen), replacing the
/// former placeholder — route unchanged (`AppRoutes.prayers` in
/// lib/navigation/route_generator.dart).
class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> with WidgetsBindingObserver {
  late final PrayerNotificationSettingsCubit _notificationCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Same singleton `PrayerTimesCubit` Home already loads from — never
    // re-fetched independently, per contracts/prayer_notification_settings_cubit_contract.md.
    PrayerTimesCubit.instance.loadPrayerTimes();
    _notificationCubit = PrayerNotificationSettingsCubit()..loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reflects a permission grant made in device settings without requiring
    // the user to fully leave and reopen the screen (contract: "permission
    // re-check on resume").
    if (state == AppLifecycleState.resumed) {
      _notificationCubit.refreshPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: PrayerTimesCubit.instance),
        BlocProvider.value(value: _notificationCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(translator.word(TranslationKeys.prayersScreenTitle)),
        ),
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: const SafeArea(child: PrayersView()),
      ),
    );
  }
}
