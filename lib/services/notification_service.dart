import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi notifikasi
  void initializeNotifications() async {
    var android = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Menampilkan notifikasi
  void showNotification() async {
    var android = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    var platform = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Service Reminder',
      'Time to change the oil!',
      platform,
    );
  }
}
