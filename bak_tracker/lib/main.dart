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
}

class BakTrackerApp extends StatelessWidget {
  const BakTrackerApp({super.key});

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
      await _navigateToInitialScreen();
    } catch (e) {
      print('Error during secondary initialization: $e');
    }
  }

  Future<void> _navigateToInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        // Fetch association data
        final List<dynamic> associationData = await Supabase.instance.client
            .from('association_members')
            .select()
            .eq('user_id', Supabase.instance.client.auth.currentUser!.id);

        // After all tasks are done, remove the splash screen
        FlutterNativeSplash.remove();

        if (associationData.isNotEmpty) {
          // User has associations, navigate to MainScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // User has no associations, navigate to NoAssociationScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const NoAssociationScreen()),
          );
        }
      } catch (e) {
        print('Error fetching association data: $e');
        // If there is an error, remove splash and navigate to NoAssociationScreen
        FlutterNativeSplash.remove();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
        );
      }
    } else {
      // No session found, remove splash and navigate to LoginScreen
      FlutterNativeSplash.remove();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing needs to be shown as the splash screen is active during this phase
    return const SizedBox.shrink();
  }
}
