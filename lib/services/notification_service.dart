// lib/services/notification_service.dart
import 'dart:async'; // Untuk StreamController
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:motocare/models/notification_item.dart' as model;
import 'package:motocare/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  StreamController<String?>? _payloadStreamController; // Deklarasikan di sini

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'motocare_channel_id',
    'MotoCare Notifikasi',
    description: 'Saluran ini digunakan untuk notifikasi penting aplikasi MotoCare.',
    importance: Importance.max,
    playSound: true,
  );

  // Modifikasi initializeNotifications untuk menerima StreamController
  Future<void> initializeNotifications(StreamController<String?> payloadStreamController) async {
    _payloadStreamController = payloadStreamController; // Simpan stream controller

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse, // Gunakan method instance
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground // Tetap static jika perlu
    );

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
     print("[NotificationService] Inisialisasi flutter_local_notifications selesai.");
  }

  // Method instance untuk menangani respons notifikasi
  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('KLIK NOTIFIKASI (foreground/background active) - PAYLOAD: $payload');
      _payloadStreamController?.add(payload); // Kirim payload ke stream
    }
  }

  // Handler statis untuk tap notifikasi dari background (jika app terminated dan dihidupkan dari notif)
  // Perlu setup tambahan yang lebih kompleks untuk skenario ini,
  // StreamController mungkin tidak langsung berfungsi jika app benar-benar baru dimulai dari terminated.
  // Untuk sekarang, fokus pada saat app di background (paused) atau foreground.
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {
    debugPrint('KLIK NOTIFIKASI (BACKGROUND/TERMINATED NATIVE HANDLER) - PAYLOAD: ${notificationResponse.payload}');
    // TODO: Untuk kasus terminated, Anda mungkin perlu menyimpan payload ini ke SharedPreferences
    // dan memeriksanya saat aplikasi dimulai di main.dart atau HomeScreen.
    // Untuk kasus background (paused), _payloadStreamController.add(payload) dari _onDidReceiveNotificationResponse
    // seharusnya cukup jika instance NotificationService dan stream masih hidup.
    // Jika NotificationService di re-create, maka stream perlu di re-subscribe.
  }


  Future<List<model.NotificationItem>> getMyNotifications() async {
    // ... (getMyNotifications tidak berubah)
    try {
      final response = await _apiService.get('/notifications/my-notifications');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<model.NotificationItem> notifications = body
            .map((dynamic item) => model.NotificationItem.fromJson(item))
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

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    // ... (markNotificationAsRead tidak berubah)
    try {
      final response = await _apiService.put('/notifications/${notificationId.toString()}/read', {});
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

  Future<void> showLocalNotification({
      required int id,
      required String title,
      required String body,
      String? payload}) async {
    // ... (showLocalNotification tidak berubah signifikan, pastikan izin sudah dihandle)
    print("[NotificationService] Mencoba menampilkan notifikasi lokal: ID $id, Title: $title");

    if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final bool? hasPermission = await androidImplementation?.areNotificationsEnabled();
        if (hasPermission != null && !hasPermission) {
            print("[NotificationService] Izin notifikasi belum ada, meminta...");
            final bool? permissionGranted = await androidImplementation?.requestNotificationsPermission();
            if (permissionGranted != null && !permissionGranted) {
                print("[NotificationService] Izin notifikasi DITOLAK oleh pengguna.");
                return;
            }
            print("[NotificationService] Izin notifikasi DIBERIKAN oleh pengguna.");
        } else {
          // print("[NotificationService] Izin notifikasi sudah ada atau tidak berlaku (Android < 13).");
        }
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
        );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics);

    try {
      await _flutterLocalNotificationsPlugin.show(
          id, title, body, platformChannelSpecifics,
          payload: payload);
      print("[NotificationService] Notifikasi lokal BERHASIL ditampilkan: ID $id, Title: $title");
    } catch (e) {
      print("[NotificationService] GAGAL menampilkan notifikasi lokal: $e");
    }
  }
}