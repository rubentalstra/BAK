import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationsService(this.flutterLocalNotificationsPlugin);

  Future<void> initializeNotifications() async {
    try {
      // print('Starting initialization of FlutterLocalNotificationsPlugin');

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

      // print('Before initializing FlutterLocalNotificationsPlugin');

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped with payload: ${response.payload}');
        },
      );

      // print('FlutterLocalNotificationsPlugin initialized successfully');
    } catch (e) {
      print('Error initializing FlutterLocalNotificationsPlugin: $e');
    }
  }

  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
      await _handleFCMToken(messaging);
    } else {
      print('User declined or did not grant notification permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message while in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Notification: ${message.notification}');
        await _showNotification(
          message.notification!,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from a notification');
      // Handle navigation or other actions based on the notification
    });
  }

  Future<void> _handleFCMToken(FirebaseMessaging messaging) async {
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Get the current user's ID
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

  Future<void> _showNotification(RemoteNotification notification) async {
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
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: notification.body,
    );
  }
}
