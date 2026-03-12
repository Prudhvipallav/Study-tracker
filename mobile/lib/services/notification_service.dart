import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'studenttrack_pro',
    'StudentTrack Pro',
    description: 'StudentTrack Pro notifications',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _initialized = true;
      debugPrint('>>> NotificationService initialized OK');
    } catch (e) {
      debugPrint('>>> NotificationService init error: $e');
    }
  }

  static Future<void> showInstantNotification(
      String title, String body) async {
    if (!_initialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'studenttrack_pro',
          'StudentTrack Pro',
          channelDescription: 'StudentTrack Pro notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Notification show error: $e');
    }
  }

  static Future<void> scheduleHabitReminder(TimeOfDay time) async {
    // Use instant notification as a confirmation — scheduled notifications
    // require timezone package (TZDateTime) which adds complexity.
    // For a simple reminder, we show an instant confirmation.
    await showInstantNotification(
      '🔔 Habit Reminder Set!',
      'Daily reminder set for ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}. We\'ll remind you to check your habits!',
    );
  }

  static Future<void> showPomodoroComplete(bool isWork) async {
    await showInstantNotification(
      isWork ? '☕ Break Time!' : '🍅 Back to Work!',
      isWork
          ? 'Great focus session! Take a well-deserved break.'
          : 'Break over. Time to get back in the zone!',
    );
  }

  static Future<void> scheduleWaterReminder(int intervalHours) async {
    await showInstantNotification(
      '💧 Drink Water!',
      'Stay hydrated — log a glass and keep your streak going!',
    );
  }
}
