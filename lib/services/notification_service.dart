// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Jika Anda pakai ini
import 'package:motocare/models/notification_item.dart';
import 'package:motocare/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  // Untuk notifikasi lokal jika Anda menggunakannya
  // static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // --- BARU: Metode untuk inisialisasi (bisa dikembangkan) ---
  Future<void> initializeNotifications() async {
    // TODO: Implementasikan logika inisialisasi notifikasi jika perlu
    // Misalnya, setup untuk flutter_local_notifications atau Firebase Messaging
    // Contoh dengan flutter_local_notifications:
    // const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // Ganti dengan ikon Anda
    // final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    // final InitializationSettings initializationSettings = InitializationSettings(
    //   android: initializationSettingsAndroid,
    //   iOS: initializationSettingsIOS,
    // );
    // await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print("NotificationService initialized (placeholder)");
  }

  // --- Metode untuk mendapatkan notifikasi pengguna ---
  Future<List<NotificationItem>> getMyNotifications() async {
    try {
      final response = await _apiService.get('/notifications/my-notifications');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<NotificationItem> notifications = body
            .map((dynamic item) => NotificationItem.fromJson(item))
            .toList();
        return notifications;
      } else {
        print('[NotificationService] Gagal mendapatkan notifikasi: ${response.statusCode} ${response.body}');
        throw Exception('Gagal memuat notifikasi. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[NotificationService] Error di getMyNotifications: $e');
      throw Exception('Terjadi kesalahan saat memuat notifikasi: ${e.toString()}');
    }
  }

  // --- Metode untuk menandai notifikasi sebagai sudah dibaca ---
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _apiService.put('/notifications/${notificationId.toString()}/read', {}); // Pastikan endpoint ini ada di backend
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Gagal menandai notifikasi'};
      }
    } catch (e) {
      print('[NotificationService] Error di markNotificationAsRead: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // Metode untuk menampilkan notifikasi lokal (contoh jika pakai flutter_local_notifications)
  // Future<void> showLocalNotification(int id, String title, String body, String? payload) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails('your_channel_id', 'your_channel_name',
  //           channelDescription: 'your_channel_description',
  //           importance: Importance.max,
  //           priority: Priority.high,
  //           showWhen: false);
  //   const NotificationDetails platformChannelSpecifics =
  //       NotificationDetails(android: androidPlatformChannelSpecifics);
  //   await _flutterLocalNotificationsPlugin.show(
  //       id, title, body, platformChannelSpecifics,
  //       payload: payload);
  // }
}
