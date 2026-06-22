import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:myapp/models/action_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

// NOTE: We avoid importing dart:html directly as it breaks mobile builds.
// For web notifications, we would ideally use a conditional import or a plugin that supports all platforms.

import 'package:universal_html/html.dart' as html;

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

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          // Handle notification tapped logic here if needed
        },
      );
      _isInitialized = true;
    } catch (e) {
      developer.log('Notification initialization failed', error: e);
      // We don't rethrow to avoid crashing the whole app
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      try {
        final permission = await html.Notification.requestPermission();
        return permission == 'granted';
      } catch (e) {
        developer.log('Web notification permission error', error: e);
        return false;
      }
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
    if (kIsWeb || !_isInitialized) return;
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      developer.log('Failed to cancel notifications', error: e);
    }
  }

  Future<void> showImmediateNotification(String title, String body) async {
    developer.log('Showing immediate notification: $title - $body');
    if (kIsWeb) {
      if (!html.Notification.supported) {
        developer.log('Web notifications are not supported in this browser.');
        return;
      }
      
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      } else {
        developer.log('Notification permission not granted. Current state: ${html.Notification.permission}');
        final granted = await requestPermissions();
        if (granted) {
          html.Notification(title, body: body);
        }
      }
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


  Future<void> sendTestNotification() async {
    await showImmediateNotification(
      'Test Notification',
      'This is a test notification from Niyan Property Management.',
    );
  }

  /// Broadcasts a notice to all members of a society.
  /// In a real app, this would trigger an FCM topic broadcast.
  Future<void> broadcastSocietyNotice({
    required String societyId,
    required String title,
    required String body,
  }) async {
    developer.log('Broadcasting notice for society $societyId: $title');
    
    // 1. Show immediate notification for the current user if they are in this society
    await showImmediateNotification(title, body);

    // 2. Persist notification in Firestore for residents to see in an 'Alerts' or 'Notifications' tab
    await FirebaseFirestore.instance.collection('society_notifications').add({
      'societyId': societyId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'notice',
    });
  }

  Future<void> _persistNotification(String ownerId, String title, String body, ActionItem item) async {
    // Use a deterministic key to avoid duplicates
    final key = '${item.tenant.id}_${item.month}_rent_reminder';
    final existing = await FirebaseFirestore.instance
        .collection('notifications')
        .where('ownerId', isEqualTo: ownerId)
        .where('dedupeKey', isEqualTo: key)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // Already persisted

    await FirebaseFirestore.instance.collection('notifications').add({
      'ownerId': ownerId,
      'title': title,
      'body': body,
      'type': 'general',
      'data': {
        'tenantId': item.tenant.id,
        'propertyId': item.propertyId,
        'unitId': item.unitId,
        'month': item.month,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'dedupeKey': key,
    });
  }

  Future<void> scheduleRentReminders(List<ActionItem> actionItems, String timeStr, String timezoneStr, String frequency, {String? ownerId}) async {
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
      
      tz.Location location;
      try {
        if (timezoneStr == 'Device Local Time' || timezoneStr.isEmpty) {
          location = tz.local;
        } else {
          location = tz.getLocation(timezoneStr);
        }
      } catch (_) {
        location = tz.local;
      }
      
      tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute, location);

      developer.log('Scheduling notification for ${item.tenant.name} at $scheduledDate');
      
      if (frequency == 'On Due Date') {
        final dueDate = item.dueDate;
        final scheduleTime = tz.TZDateTime(location, dueDate.year, dueDate.month, dueDate.day, hour, minute);
        if (scheduleTime.isBefore(tz.TZDateTime.now(location))) {
            developer.log('Skipping ${item.tenant.name} - due date is in the past.');
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
              showWhen: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: frequency == 'Daily' ? DateTimeComponents.time : 
                                   (frequency == 'Weekly' ? DateTimeComponents.dayOfWeekAndTime : null),
        );
        // Persist to Firestore so it shows in the Alerts tab
        if (ownerId != null) {
          await _persistNotification(ownerId, title, body, item);
        }
      } catch (e) {
        developer.log('Error scheduling notification for ${item.tenant.name}', error: e);
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, tz.Location location) {
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    
    // If it's already past this time today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

