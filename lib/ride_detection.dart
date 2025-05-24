import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RideDetection {
  late double x;
  late double y;
  late double z;
  double speed = 0.0; // speed in km/h
  bool isMotorcycle = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize sensor for accelerometer
  void initSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      x = event.x;
      y = event.y;
      z = event.z;
      detectMotorcycleVibration();
    });
  }

  // Initialize GPS for speed
  void getCurrentSpeed() async {
    try {
      // Pastikan izin lokasi sudah diberikan sebelum memanggil ini.
      // Anda bisa menambahkan pengecekan izin di sini atau di level yang lebih tinggi.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Layanan lokasi tidak aktif, jangan lanjutkan.
        // Anda bisa memberi tahu pengguna atau mencoba meminta layanan diaktifkan.
        print('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied, we cannot request permissions.');
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      speed = position.speed * 3.6; // converting m/s to km/h
      detectMotorcycleSpeed();
    } catch (e) {
      print("Error getting current speed: $e");
    }
  }

  // Check if user is riding a motorcycle based on vibration data
  void detectMotorcycleVibration() {
    // Define the thresholds based on your data (from the research paper)
    double vibrationThresholdX = 0.5;
    double vibrationThresholdY = 1.0;
    double vibrationThresholdZ = 1.5;

    // If vibration exceeds thresholds, it's likely a motorcycle
    if (x.abs() > vibrationThresholdX && y.abs() > vibrationThresholdY && z.abs() > vibrationThresholdZ) { // Menggunakan .abs() untuk nilai absolut getaran
      isMotorcycle = true;
    } else {
      isMotorcycle = false;
    }
  }

  // Check if the speed exceeds 25 km/h (threshold for motorcycle)
  void detectMotorcycleSpeed() {
    if (speed > 25.0 && isMotorcycle) {
      sendNotification(payload: "ride_detected_at_${speed.toStringAsFixed(1)}kmh"); // Menambahkan payload
    }
  }

  // Send a notification
  void sendNotification({String? payload}) async { // Menambahkan parameter payload
    var androidDetails = AndroidNotificationDetails(
      'motorcycle_channel', 
      'Motorcycle Ride Notifications', 
      channelDescription: 'This channel notifies users about motorcycle rides',
      importance: Importance.high, 
      priority: Priority.high);

    var generalNotificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, 
      'Ride Detection', 
      'Did you use the registered motorcycle during your trip?', 
      generalNotificationDetails,
      payload: payload // Menggunakan payload yang diberikan
    );
  }

  // GANTI FUNGSI INI: dari _onSelectNotification ke _onDidReceiveNotificationResponse
  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('NOTIFICATION RESPONSE payload: $payload');
      // Handle tap event di sini.
      // Contoh: Anda bisa melakukan navigasi atau menampilkan data berdasarkan payload
      // Jika menggunakan navigator global:
      // MyApp.navigatorKey.currentState?.pushNamed('/some_route', arguments: payload);
    }
  }

  void initialize() async {
    // Pastikan 'app_icon' adalah nama file ikon Anda (tanpa ekstensi)
    // dan ada di android/app/src/main/res/drawable/ (misalnya app_icon.png)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // Pengaturan untuk iOS (opsional, jika menargetkan iOS)
    // const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    //   requestAlertPermission: true,
    //   requestBadgePermission: true,
    //   requestSoundPermission: true,
    //   // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // untuk iOS versi lama
    // );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsIOS,
    );

    // GUNAKAN onDidReceiveNotificationResponse di sini
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }
}