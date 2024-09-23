import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/themes.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/core/utils/my_secure_storage.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load the environment variables and initialize Firebase and Supabase in parallel
    await Future.wait([
      dotenv.load(fileName: ".env"),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);

    print('Firebase and .env loaded successfully.');

    // Initialize Supabase using environment variables
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
    );

    print('Supabase initialized successfully.');

    // Initialize Local Notifications Plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final NotificationsService notificationsService =
        NotificationsService(flutterLocalNotificationsPlugin);

    // Initialize notifications and Firebase messaging
    await notificationsService.initializeNotifications();
    await notificationsService.setupFirebaseMessaging();

    // Register the background message handler for Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(
        NotificationsService.firebaseMessagingBackgroundHandler);

    print('Notifications service initialized successfully.');

    // After all the initializations, decide which screen to navigate to
    final initialScreen = await _getInitialScreen(notificationsService);

    // Now, run the app
    runApp(BakTrackerApp(
      notificationsService: notificationsService,
      initialScreen: initialScreen,
    ));
  } catch (e) {
    print('Error during app initialization: $e');
    // If there is an error, you can handle it by showing an error screen or alert
  }
}

Future<Widget> _getInitialScreen(
    NotificationsService notificationsService) async {
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null) {
    // Request Firebase messaging permissions
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await notificationsService.handleFCMToken(messaging);
    }

    // Check if the user is part of any association
    final List<dynamic> associations = await Supabase.instance.client
        .from('association_members')
        .select()
        .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

    if (associations.isNotEmpty) {
      return const MainScreen(); // User has associations, go to home screen
    } else {
      return const NoAssociationScreen(); // User has no associations
    }
  } else {
    // If no session is found, navigate to the login screen
    return const LoginScreen();
  }
}

class BakTrackerApp extends StatelessWidget {
  final NotificationsService notificationsService;
  final Widget initialScreen;

  const BakTrackerApp({
    super.key,
    required this.notificationsService,
    required this.initialScreen,
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
            home:
                initialScreen, // Start directly on the resolved initial screen
          );
        },
      ),
    );
  }
}
