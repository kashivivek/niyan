import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:myapp/models/action_item_model.dart';
import 'dart:developer' as developer;

// NOTE: We avoid importing dart:html directly as it breaks mobile builds.
// For web notifications, we would ideally use a conditional import or a plugin that supports all platforms.

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tapped logic here if needed
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      // On web, we would use html.Notification.requestPermission()
      // For now, we skip to avoid build errors on mobile.
      return true;
    }

    bool? androidGranted = false;
    bool? iosGranted = false;

    try {
      final androidImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        androidGranted = await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      final iosImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      developer.log('Notification permission request error', error: e);
    }

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showImmediateNotification(String title, String body) async {
    if (kIsWeb) {
      debugPrint('Web Notification: $title - $body');
      return;
    }

    await _flutterLocalNotificationsPlugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_channel',
          'Immediate Notifications',
          channelDescription: 'Confirmations and immediate alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleRentReminders(List<ActionItem> actionItems, String timeStr, String frequency) async {
    if (kIsWeb) return;

    await cancelAllNotifications(); // Clear existing
    if (actionItems.isEmpty) return;

    // Parse timeStr e.g. "09:00"
    int hour = 9;
    int minute = 0;
    try {
      final parts = timeStr.split(':');
      hour = int.parse(parts[0]);
      minute = int.parse(parts[1]);
    } catch (_) {}

    int notificationId = 0;

    for (final item in actionItems) {
      final title = 'Rent Due: ${item.tenant.name}';
      final body = '${item.amount.toStringAsFixed(0)} is ${item.isOverdue ? 'overdue' : 'due'} for ${item.month}.';
      
      tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      if (frequency == 'On Due Date') {
        final dueDate = item.dueDate;
        final scheduleTime = tz.TZDateTime.local(dueDate.year, dueDate.month, dueDate.day, hour, minute);
        if (scheduleTime.isBefore(tz.TZDateTime.now(tz.local))) {
            continue;
        }
        scheduledDate = scheduleTime;
      }

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId++,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'rent_reminders_channel',
              'Rent Reminders',
              channelDescription: 'Notifications for upcoming or overdue rent payments.',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: frequency == 'Daily' ? DateTimeComponents.time : 
                                   (frequency == 'Weekly' ? DateTimeComponents.dayOfWeekAndTime : null),
        );
      } catch (e) {
        developer.log('Error scheduling notification for ${item.tenant.name}', error: e);
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
