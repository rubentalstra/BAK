import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/themes.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/ui/splash/splash_screen.dart';
import 'package:bak_tracker/core/utils/my_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Keep splash screen visible while the app is initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Load environment variables
    await dotenv.load(fileName: ".env");
    print('.env file loaded successfully');

    // Initialize Supabase using environment variables
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        localStorage: MySecureStorage(), // Use custom secure storage
      ),
    );
    print('Supabase initialized successfully');

    // Initialize Local Notifications Plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialize Notifications Service
    final NotificationsService notificationsService =
        NotificationsService(flutterLocalNotificationsPlugin);

    // Initialize notifications (local notifications + Firebase messaging setup)
    await notificationsService.initializeNotifications();
    await notificationsService
        .setupFirebaseMessaging(); // Setup Firebase messaging

    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(
        NotificationsService.firebaseMessagingBackgroundHandler);

    print('Notifications service initialized successfully');

    // Run the application
    runApp(BakTrackerApp(
      notificationsService: notificationsService,
    ));
  } catch (e) {
    print('Error during app initialization: $e');
    // Handle initialization error, possibly show an error screen
  }

  // Remove splash screen once the app has initialized
  FlutterNativeSplash.remove();
}

class BakTrackerApp extends StatelessWidget {
  final NotificationsService notificationsService;

  const BakTrackerApp({
    super.key,
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
