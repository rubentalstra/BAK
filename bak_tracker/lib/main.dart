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
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';

void main() async {
  // Keep the splash screen visible while the app is initializing
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Load environment variables, Firebase, and Supabase in parallel
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
    );

    print('Firebase, Supabase, and .env loaded successfully.');

    // After initialization, run the app
    runApp(BakTrackerApp());
  } catch (e) {
    print('Error during app initialization: $e');
  }

  // Remove splash screen after initialization is complete
  FlutterNativeSplash.remove();
}

class BakTrackerApp extends StatelessWidget {
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
            home: const AppStartup(), // Delayed logic handled here
          );
        },
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  _AppStartupState createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late NotificationsService notificationsService;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Notifications and Firebase Messaging lazily
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      notificationsService =
          NotificationsService(flutterLocalNotificationsPlugin);
      await notificationsService.initializeNotifications();
      await notificationsService.setupFirebaseMessaging();

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
          NotificationsService.firebaseMessagingBackgroundHandler);

      // Check for the initial screen after setting up services
      _navigateToInitialScreen();
    } catch (e) {
      print('Error during secondary initialization: $e');
    }
  }

  Future<void> _navigateToInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Fetch association data in the background
      final Future<List<dynamic>> associationFuture = Supabase.instance.client
          .from('association_members')
          .select()
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

      // Navigate to the appropriate screen based on the association data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FutureBuilder<List<dynamic>>(
            future: associationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return const MainScreen(); // User has associations
              } else {
                return const NoAssociationScreen(); // User has no associations
              }
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Placeholder while initialization occurs
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
