import 'package:sakinah/shared/bloc/session_cubit.dart';
import 'package:sakinah/shared/bloc/settings_cubit.dart';
import 'package:sakinah/configurations/app_env.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/navigation/app_routes.dart';
import 'package:sakinah/utils/style/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'handlers/translation_handler.dart';
import 'navigation/route_generator.dart';

String env = 'dev';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.init(env);
  AESEncryptor.init();
  await SharedPrefHandler.init();
  await Supabase.initialize(
    url: AppEnv.instance.supabaseUrl,
    publishableKey: AppEnv.instance.supabaseAnonKey,
  );
  await SessionCubit.instance.restoreSession();
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
      ],
      child: BlocBuilder<SettingsCubit, AppStates>(
        builder: (context, state) {
          return MaterialApp(
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: SettingsCubit.instance.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: SettingsCubit.instance.locale,
            onGenerateRoute: generateRoute,
            initialRoute: AppRoutes.login,
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
