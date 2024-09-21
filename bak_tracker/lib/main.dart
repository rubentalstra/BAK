import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/themes.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/ui/splash/splash_screen.dart';
import 'package:bak_tracker/core/utils/my_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  // Initialize Supabase using environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: FlutterAuthClientOptions(
      localStorage: MySecureStorage(), // Use custom secure storage
    ),
  );

  // Initialize Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize Notifications Service
  final NotificationsService notificationsService =
      NotificationsService(flutterLocalNotificationsPlugin);

  // Initialize notifications (local notifications + Firebase messaging setup)
  await notificationsService.initializeNotifications();

  runApp(BakTrackerApp(
    flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
    notificationsService: notificationsService, // Pass the service here
  ));

  FlutterNativeSplash.remove();
}

class BakTrackerApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final NotificationsService notificationsService;

  const BakTrackerApp({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    required this.notificationsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssociationBloc>(create: (_) => AssociationBloc()),
        BlocProvider<AuthenticationBloc>(create: (_) => AuthenticationBloc()),
        BlocProvider<LocaleBloc>(create: (_) => LocaleBloc()),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            title: 'Bak Tracker',
            theme: AppThemes.darkTheme,
            locale: localeState.locale,
            debugShowCheckedModeBanner: false,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashScreen(notificationsService: notificationsService),
          );
        },
      ),
    );
  }
}
