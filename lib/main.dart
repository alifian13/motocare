// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/notification_service.dart';
import 'services/user_service.dart';

import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notification_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/settings_screen.dart'; // <-- 2. IMPORT HALAMAN PENGATURAN

// Global StreamController untuk event klik notifikasi
final StreamController<String?> notificationPayloadStream = StreamController<String?>.broadcast();

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('id_ID', null);

  print("MAIN: Menginisialisasi NotificationService...");
  await notificationService.initializeNotifications(notificationPayloadStream);
  print("MAIN: NotificationService telah diinisialisasi.");

  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Berdasarkan kode Anda, key yang benar adalah 'token'
  String? token = prefs.getString('token'); 

  runApp(MotorApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MotorApp extends StatelessWidget {
  final bool isLoggedIn;
  const MotorApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
          hintStyle: TextStyle(color: Colors.grey[500])
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
        )
      ),
      initialRoute: isLoggedIn ? HomeScreen.routeName : LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        HistoryScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            final vehicleId = arguments['vehicleId'] as int?;
            final plateNumber = arguments['plateNumber'] as String?;
            if (vehicleId != null) {
              return HistoryScreen(vehicleId: vehicleId, plateNumber: plateNumber);
            }
          }
          return Scaffold(
              appBar: AppBar(title: const Text("Error Navigasi")),
              body: const Center(child: Text("ID Kendaraan tidak valid untuk Riwayat.")));
        },
        ScheduleScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            final vehicleId = arguments['vehicleId'] as String?;
            final plateNumber = arguments['plateNumber'] as String?;
            if (vehicleId != null) {
              return ScheduleScreen(vehicleId: vehicleId, plateNumber: plateNumber);
            }
          }
          return Scaffold(
              appBar: AppBar(title: const Text("Error Navigasi")),
              body: const Center(child: Text("ID Kendaraan tidak valid untuk Jadwal.")));
        },
        NotificationListScreen.routeName: (context) => const NotificationListScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        ContactUsScreen.routeName: (context) => const ContactUsScreen(),
        // --- 4. DAFTARKAN ROUTE BARU UNTUK PENGATURAN ---
        SettingsScreen.routeName: (context) => SettingsScreen(),
        // ---------------------------------------------
      },
    );
  }
}