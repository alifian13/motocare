import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RideDetection {
  late double x;
  late double y;
  late double z;
  double speed = 0.0;
  bool isMotorcycle = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void initSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      x = event.x;
      y = event.y;
      z = event.z;
      detectMotorcycleVibration();
    });
  }

  void getCurrentSpeed() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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
      speed = position.speed * 3.6;
      detectMotorcycleSpeed();
    } catch (e) {
      print("Error getting current speed: $e");
    }
  }

  void detectMotorcycleVibration() {
    double vibrationThresholdX = 0.5;
    double vibrationThresholdY = 1.0;
    double vibrationThresholdZ = 1.5;

    if (x.abs() > vibrationThresholdX && y.abs() > vibrationThresholdY && z.abs() > vibrationThresholdZ) { // Menggunakan .abs() untuk nilai absolut getaran
      isMotorcycle = true;
    } else {
      isMotorcycle = false;
    }
  }

  void detectMotorcycleSpeed() {
    if (speed > 25.0 && isMotorcycle) {
      sendNotification(payload: "ride_detected_at_${speed.toStringAsFixed(1)}kmh"); // Menambahkan payload
    }
  }

  void sendNotification({String? payload}) async {
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
      payload: payload
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('NOTIFICATION RESPONSE payload: $payload');
    }
  }

  void initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }
}