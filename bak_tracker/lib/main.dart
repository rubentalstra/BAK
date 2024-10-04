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

  try {
    // Initialize Firebase and Supabase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: MySecureStorage()),
    );
    print('Firebase and Supabase initialized successfully.');

    // Initialize App Info Service to fetch version and build number
    await appInfoService.initializeAppInfo();

    await HomeWidget.setAppGroupId('group.com.baktracker.shared');

    // Run the main app
    runApp(const BakTrackerApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Optionally, you could run a minimal app that shows an error screen
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
            title: 'BAK*',
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

  @override
  void dispose() {
    // Clean up services and handlers
    deepLinkService.dispose();
    flutterLocalNotificationsPlugin
        .cancelAll(); // Ensure notifications are cancelled
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _initializeNotifications();
      await _initializeDeepLinks();
    } catch (e) {
      print('Error during initialization: $e');
      // Handle initialization errors if necessary
    } finally {
      // Remove the splash screen after all initializations
      if (mounted) {
        FlutterNativeSplash.remove();
        await _navigateToInitialScreen();
      }
    }
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    notificationsService =
        NotificationsService(flutterLocalNotificationsPlugin);
    await notificationsService.initializeNotifications();
    await notificationsService.setupFirebaseMessaging();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(
        NotificationsService.firebaseMessagingBackgroundHandler);
  }

  Future<void> _initializeDeepLinks() async {
    final associationBloc = context.read<AssociationBloc>();
    // Initialize deepLinkService properly
    deepLinkService = DeepLinkService(
      associationBloc: associationBloc,
      navigateToMainScreen: _navigateToMainScreen,
      onError: (String error) {
        // Use BuildContext here to show the snackbar in the UI layer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );

    // Now call initialize on deepLinkService
    deepLinkService.initialize();
  }

  Future<void> _navigateToInitialScreen() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in
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
      // User is not logged in
      _navigateToLoginScreen();
    }
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
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

  void _navigateToLoginScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Since all initialization is done asynchronously, we return an empty container here.
    return const SizedBox.shrink();
  }
}
