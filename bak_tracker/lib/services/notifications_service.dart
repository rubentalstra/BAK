import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:bak_tracker/core/const/notification_messages.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Set<String> _shownNotificationIds = {}; // Store notification IDs

  NotificationsService(this.flutterLocalNotificationsPlugin) {
    tz.initializeTimeZones();
  }

  Future<void> initializeNotifications() async {
    await _requestNotificationPermissions();
    await _initializePlatformSettings();
    await _createNotificationChannel();
    await _resetBadgeCount();
  }

  // Platform-specific notification settings initialization
  Future<void> _initializePlatformSettings() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification tapped with payload: ${response.payload}');
        _resetBadgeCount(); // Reset badge when notification is tapped
      },
    );
  }

  // Creating a notification channel for Android 8.0+
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // Unique ID
      'your_channel_name', // Human readable name
      description: 'your_channel_description', // Description for the channel
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Request notification permissions using permission_handler
  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final permissionGranted = await Permission.notification.request();
      if (permissionGranted.isGranted) {
        print('Notification permission granted.');
      } else {
        print('Notification permission denied.');
      }
    }
  }

  // Setup Firebase Messaging for handling FCM notifications
  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await handleFCMToken(messaging);
    }

    FirebaseMessaging.onMessage
        .listen((message) => _handleForegroundMessage(message));

    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _resetBadgeCount());
  }

  // Handle Firebase Cloud Messaging (FCM) token for the current user
  Future<void> handleFCMToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (token != null && userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token}).eq('id', userId);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Handle foreground notifications
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.messageId != null &&
        !_shownNotificationIds.contains(message.messageId!)) {
      _shownNotificationIds.add(message.messageId!);

      if (message.notification != null) {
        final title = message.notification?.title ?? 'No title';
        final body = message.notification?.body ?? 'No body';
        await _showNotification(title, body);
        await _incrementBadgeCount();
      }
    }
  }

  // Show a local notification using FlutterLocalNotificationsPlugin
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      body.hashCode, // Unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: body,
    );
  }

// Scheduling a streak reminder notification dynamically
  Future<void> scheduleStreakReminder(UserModel user) async {
    final now = DateTime.now();
    DateTime reminderTime =
        DateTime(now.year, now.month, now.day, 20, 0); // 8 PM today

    // If the current time is already past 8 PM, schedule for tomorrow
    if (now.isAfter(reminderTime)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    String title;
    String body;

    if (user.alcoholStreak > 0) {
      final hoursRemaining = reminderTime.difference(now).inHours;
      if (hoursRemaining <= 2) {
        // Last chance
        title = NotificationMessages.streakLastChanceTitle;
        body = NotificationMessages.streakLastChanceBody;
      } else if (hoursRemaining <= 6) {
        // Streak is on fire
        title = NotificationMessages.streakOnFireTitle;
        body = NotificationMessages.streakOnFireBody;
      } else {
        // Default reminder
        title = NotificationMessages.streakReminderTitle;
        body = NotificationMessages.streakReminderBody;
      }

      await scheduleNotification(
        title: title,
        body: body,
        scheduledTime: reminderTime,
      );
    }
  }

  // Cancel scheduled streak reminders
  Future<void> cancelStreakReminder() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime localScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      localScheduledTime.hashCode,
      title,
      body,
      localScheduledTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Increment the badge count and store it persistently
  Future<void> _incrementBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
    currentBadgeCount++;
    await prefs.setInt('badge_count', currentBadgeCount);
    AppBadgePlus.updateBadge(currentBadgeCount);
  }

  // Reset the badge count and update storage
  Future<void> _resetBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badge_count', 0);
    AppBadgePlus.updateBadge(0);
  }

  // Background message handler
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    final title = message.data['title'] ?? 'No title';
    final body = message.data['body'] ?? 'No body';

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      body.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: body,
    );

    final prefs = await SharedPreferences.getInstance();
    int currentBadgeCount = prefs.getInt('badge_count') ?? 0;
    currentBadgeCount++;
    await prefs.setInt('badge_count', currentBadgeCount);
    AppBadgePlus.updateBadge(currentBadgeCount);
  }
}
