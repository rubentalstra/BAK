import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/deep_link_service.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/auth/auth_bloc.dart';
import 'package:bak_tracker/bloc/locale/locale_bloc.dart';
import 'package:bak_tracker/core/themes/themes.dart';
import 'package:bak_tracker/services/join_association_service.dart';
import 'package:bak_tracker/services/notifications_service.dart';
import 'package:bak_tracker/services/app_info_service.dart';
import 'package:bak_tracker/core/utils/my_secure_storage.dart';
import 'package:bak_tracker/services/user_service.dart';
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
    final supabaseClient = Supabase.instance.client;
    final associationService = AssociationService(supabaseClient);
    final userService = UserService(supabaseClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AssociationBloc>(
            create: (_) => AssociationBloc(associationService)),
        BlocProvider<AuthenticationBloc>(create: (_) => AuthenticationBloc()),
        BlocProvider<LocaleBloc>(create: (_) => LocaleBloc()),
        BlocProvider<UserBloc>(create: (_) => UserBloc(userService)),
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
      _initializeBackgroundServices(); // Load background services
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      if (mounted) {
        FlutterNativeSplash.remove(); // Remove splash screen
      }
    }
  }

  // Load background services without blocking the main flow
  Future<void> _initializeBackgroundServices() async {
    try {
      await Future.wait([
        _initializeNotifications(),
        _initializeDeepLinks(),
      ]);
    } catch (e) {
      print('Error during background service initialization: $e');
    }
  }

  // Navigate to the appropriate initial screen based on authentication state
  Future<void> _navigateToInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        final associationData = await Supabase.instance.client
            .from('association_members')
            .select()
            .eq('user_id', session.user.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (associationData.isNotEmpty) {
            print('User is part of an association.');
            _navigateToMainScreen();
          } else {
            _navigateToNoAssociationScreen();
          }
        });
      } catch (e) {
        print('Error fetching association data: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToNoAssociationScreen();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToLoginScreen();
      });
    }
  }

  // Initialize notifications and Firebase messaging
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    notificationsService =
        NotificationsService(flutterLocalNotificationsPlugin);

    // Set up notifications and Firebase Messaging
    await notificationsService.initializeNotifications();
    await notificationsService.setupFirebaseMessaging();

    FirebaseMessaging.onBackgroundMessage(
        NotificationsService.firebaseMessagingBackgroundHandler);

    // Reset badge count on startup
    AppBadgePlus.updateBadge(0);
  }

  // Initialize deep linking functionality
  Future<void> _initializeDeepLinks() async {
    final associationBloc = context.read<AssociationBloc>();

    deepLinkService = DeepLinkService(
      associationBloc: associationBloc,
      navigateToMainScreen: _navigateToMainScreen,
      joinAssociationService: JoinAssociationService(),
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

  // Navigation methods
  void _navigateToMainScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    });
  }

  void _navigateToNoAssociationScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const NoAssociationScreen()),
          (route) => false,
        );
      }
    });
  }

  void _navigateToLoginScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
