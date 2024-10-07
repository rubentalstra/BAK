import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:bak_tracker/services/deep_link_service.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/themes.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/services/app_info_service.dart';
import 'package:bak_tracker/core/utils/my_secure_storage.dart';
import 'package:bak_tracker/ui/home/main_screen.dart';
import 'package:bak_tracker/ui/no_association/no_association_screen.dart';
import 'package:bak_tracker/ui/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bak_tracker/env/env.dart';
import 'firebase_options.dart';

// Initialize the AppInfoService globally
final AppInfoService appInfoService = AppInfoService();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Ensure that core services like Supabase and Firebase are initialized before running the app
  await _initializeCoreServices();

  runApp(const BakTrackerApp()); // Run the app only after initialization
}

Future<void> _initializeCoreServices() async {
  try {
    // Initialize Firebase and Supabase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
    );
    print('Firebase and Supabase initialized successfully.');

    // Initialize App Info Service to fetch version and build number
    await appInfoService.initializeAppInfo();

    await HomeWidget.setAppGroupId('group.com.baktracker.shared');
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
            title: 'BAK',
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
            home: const AppStartup(),
          );
        },
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  AppStartupState createState() => AppStartupState();
}

class AppStartupState extends State<AppStartup> {
  late NotificationsService notificationsService;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late DeepLinkService deepLinkService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      await _navigateToInitialScreen();
      // Start loading non-critical services in the background
      _initializeBackgroundServices();
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      if (mounted) {
        FlutterNativeSplash.remove(); // Remove splash screen early
      }
    }
  }

  // Initialize services that are not essential for startup
  Future<void> _initializeBackgroundServices() async {
    try {
      await _initializeNotifications();
      await _initializeDeepLinks();
    } catch (e) {
      print('Error during background service initialization: $e');
    }
  }

  // Navigate directly to the initial screen (MainScreen or LoginScreen)
  Future<void> _navigateToInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        final associationData = await Supabase.instance.client
            .from('association_members')
            .select()
            .eq('user_id', session.user.id);

        if (associationData.isNotEmpty) {
          _navigateToMainScreen();
        } else {
          _navigateToNoAssociationScreen();
        }
      } catch (e) {
        print('Error fetching association data: $e');
        _navigateToNoAssociationScreen();
      }
    } else {
      _navigateToLoginScreen();
    }
  }

  // Initialize notifications (non-blocking)
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    notificationsService =
        NotificationsService(flutterLocalNotificationsPlugin);

    // Set up local notifications and Firebase Messaging
    await notificationsService.initializeNotifications();
    await notificationsService.setupFirebaseMessaging();

    FirebaseMessaging.onBackgroundMessage(
        NotificationsService.firebaseMessagingBackgroundHandler);

    // Reset badge at startup
    AppBadgePlus.updateBadge(0);
  }

  Future<void> _initializeDeepLinks() async {
    final associationBloc = context.read<AssociationBloc>();

    deepLinkService = DeepLinkService(
      associationBloc: associationBloc,
      navigateToMainScreen: _navigateToMainScreen,
      onError: (String error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
    );

    await deepLinkService.initialize();
  }

  void _navigateToLoginScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void _navigateToNoAssociationScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
