import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Set<String> _shownNotificationIds = {}; // Store notification IDs

  NotificationsService(this.flutterLocalNotificationsPlugin);

  // Initialize local notifications
  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(
              '@drawable/ic_notification'); // Ensure the icon exists in mipmap

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped with payload: ${response.payload}');
        },
      );

      print('FlutterLocalNotificationsPlugin initialized successfully');

      // Create notification channels for Android 8.0 and above
      await _createNotificationChannel();
    } catch (e) {
      print('Error initializing FlutterLocalNotificationsPlugin: $e');
    }
  }

  // Create notification channels for Android 8.0 and above
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // Unique ID
      'your_channel_name', // Human readable name
      description: 'your_channel_description', // Description for the channel
      importance: Importance.high,
    );

    // Register the channel with the system
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Set up Firebase Messaging
  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Disable default notification handling by Firebase when the app is in the foreground
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await handleFCMToken(messaging);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message while in the foreground!');

      if (message.messageId != null &&
          !_shownNotificationIds.contains(message.messageId)) {
        _shownNotificationIds.add(message.messageId!);

        if (message.notification != null) {
          RemoteNotification? notification = message.notification;
          String title = notification?.title ?? 'No title';
          String body = notification?.body ?? 'No body';
          print('Notification: Title - $title, Body - $body');
          await _showNotification(title, body);
        }
      } else {
        print('Duplicate notification received, skipping...');
      }
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from a notification');
    });
  }

  // Background message handler
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background/terminated message: ${message.messageId}');
    if (message.data.isNotEmpty) {
      String title = message.data['title'] ?? 'No title';
      String body = message.data['body'] ?? 'No body';

      // Initialize the notification plugin (if necessary) and show notification
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('your_channel_id', 'your_channel_name',
              channelDescription: 'your_channel_description',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              icon: '@drawable/ic_notification');
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: DarwinNotificationDetails());

      await flutterLocalNotificationsPlugin.show(
        body.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: body,
      );
    }
  }

  // Handle Firebase Cloud Messaging (FCM) token and save it in the Supabase database
  Future<void> handleFCMToken(FirebaseMessaging messaging) async {
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          try {
            // Update FCM token in the database
            await Supabase.instance.client
                .from('users')
                .update({'fcm_token': token}).eq('id', userId);

            print('FCM token updated successfully.');
          } catch (e) {
            print('Error updating FCM token: $e');
          }
        } else {
          print('User not logged in. Cannot update FCM token.');
        }
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon:
                '@drawable/ic_notification'); // Fallback to ic_launcher for notification icon

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.show(
      body.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: body,
    );
  }
}
