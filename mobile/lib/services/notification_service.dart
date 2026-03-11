import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'studenttrack_pro',
    'StudentTrack Pro',
    description: 'StudentTrack Pro notifications',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showInstantNotification(
      String title, String body) async {
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
  }

  static Future<void> scheduleHabitReminder(TimeOfDay time) async {
    await _plugin.cancelAll();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'studenttrack_pro',
        'StudentTrack Pro',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.zonedSchedule(
      1,
      '🔁 Habit Check-in Time!',
      "Don't forget your daily habits — keep the streak alive!",
      // ignore: deprecated_member_use
      scheduled as dynamic,
      details,
      // ignore: deprecated_member_use
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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
    // Show immediate notification and let user set it up
    await showInstantNotification(
      '💧 Drink Water!',
      'Stay hydrated — log a glass and keep your streak going!',
    );
  }
}
