import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  final Set<String> _shownNotificationIds = {}; // Store notification IDs

  NotificationsService(this.flutterLocalNotificationsPlugin);

  // Initialize local notifications
  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(
              'ic_launcher'); // Ensure the icon exists

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
    } catch (e) {
      print('Error initializing FlutterLocalNotificationsPlugin: $e');
    }
  }

  // Set up Firebase Messaging
  Future<void> setupFirebaseMessaging() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isInitialized = true; // Mark as initialized

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
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
      print('User granted notification permission');
      await _handleFCMToken(messaging);
    } else {
      print('User declined or did not grant notification permission');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message while in the foreground!');

      if (message.messageId != null &&
          !_shownNotificationIds.contains(message.messageId)) {
        // Store message ID to prevent showing the same notification twice
        _shownNotificationIds.add(message.messageId!);

        // Handle notification if present
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
      // Handle navigation or other actions based on the notification
    });
  }

  // Handle Firebase Cloud Messaging (FCM) token and save it in the Supabase database
  Future<void> _handleFCMToken(FirebaseMessaging messaging) async {
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
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.show(
      body.hashCode, // Use the body hash code as the notification ID to avoid duplicates
      title,
      body,
      platformChannelSpecifics,
      payload: body,
    );
  }
}
