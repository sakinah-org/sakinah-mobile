import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sakinah/features/quran/presentation/bloc/quran_font_settings_cubit.dart';
import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/bloc/settings_cubit.dart';
import 'package:sakinah/shared/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/handlers/fcm_handler.dart';
import 'package:sakinah/handlers/notification_handler.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/navigation/app_routes.dart';
import 'package:sakinah/utils/style/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'handlers/translation_handler.dart';
import 'navigation/route_generator.dart';

/// Must be a top-level (or static) function, tagged `vm:entry-point` so the
/// Android build doesn't tree-shake it — the plugin invokes it on a
/// separate background isolate that never ran `main()`, so Firebase has to
/// be initialized again here before touching anything Firebase-related.
/// This message already carries a `notification` block (see
/// send-prayer-reminders), which the OS auto-displays on its own in this
/// state — this handler exists so background/terminated delivery is wired
/// up for any future data-only message too.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await AppEnv.init(env);
  AESEncryptor.init();
  await SharedPrefHandler.init();
  await SettingsCubit.instance.loadPersistedSettings();
  // Required before any `DateFormat`/Hijri day-name formatting for a
  // non-'en' locale (Home's greeting header, prayer-time captions).
  await initializeDateFormatting();
  await Supabase.initialize(
    url: AppEnv.instance.supabaseUrl,
    publishableKey: AppEnv.instance.supabaseAnonKey,
  );
  await NotificationHandler.instance.init();
  await FcmHandler.instance.initListeners();
  await SessionCubit.instance.restoreSession();
  // Runs after restoreSession() so an authenticated user's remote font
  // setting (if any) is adopted using the correct SessionCubit.currentUser.
  await QuranFontSettingsCubit.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsCubit.instance),
        BlocProvider(create: (context) => SessionCubit.instance),
        BlocProvider(create: (context) => PrayerTimesCubit.instance),
        BlocProvider(create: (context) => QuranFontSettingsCubit.instance),
      ],
      child: BlocBuilder<SettingsCubit, AppStates>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: NotificationHandler.instance.navigatorKey,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: SettingsCubit.instance.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: SettingsCubit.instance.locale,
            onGenerateRoute: generateRoute,
            initialRoute: AppRoutes.main,
            // home: NotificationPages(),
            debugShowCheckedModeBanner: false,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
