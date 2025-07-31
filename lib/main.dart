import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'services/notification_service.dart';
import 'models/vehicle_model.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notification_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spare_part_list_screen.dart';

final StreamController<String?> notificationPayloadStream =
    StreamController<String?>.broadcast();

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  await initializeDateFormatting('id_ID', null);

  await notificationService.initializeNotifications(notificationPayloadStream);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  runApp(MotorApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MotorApp extends StatelessWidget {
  final bool isLoggedIn;
  const MotorApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);
    const Color secondaryColor = Color(0xFF1976D2);
    const Color accentColor = Color(0xFF42A5F5);
    const Color backgroundColor = Color(0xFFF4F6F8);
    const Color cardColor = Colors.white;
    const Color textColor = Color(0xFF333333);
    const Color secondaryTextColor = Color(0xFF5f6368);

    return MaterialApp(
      title: 'MotoCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,

        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0.5,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: accentColor, width: 2.0),
          ),
          labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),

        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
              fontSize: 28.0, fontWeight: FontWeight.bold, color: textColor),
          titleLarge: GoogleFonts.poppins(
              fontSize: 22.0, fontWeight: FontWeight.w600, color: textColor),
          titleMedium: GoogleFonts.poppins(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor),
          bodyLarge: GoogleFonts.poppins(fontSize: 16.0, color: textColor),
          bodyMedium:
              GoogleFonts.poppins(fontSize: 14.0, color: secondaryTextColor),
          labelSmall: GoogleFonts.poppins(
              fontSize: 12.0,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w500),
        ),

        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardColor,
          background: backgroundColor,
          error: Colors.redAccent,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textColor,
          onBackground: textColor,
          onError: Colors.white,
        ),
      ),
      initialRoute: isLoggedIn ? HomeScreen.routeName : LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        HistoryScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic> &&
              arguments.containsKey('vehicleId')) {
            final vehicleId = arguments['vehicleId'] as int;
            final plateNumber = arguments['plateNumber'] as String?;
            return HistoryScreen(
                vehicleId: vehicleId, plateNumber: plateNumber);
          }
          return _buildErrorRoute("ID Kendaraan tidak valid untuk Riwayat.");
        },
        ScheduleScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          // Sekarang kita cek apakah argumen 'vehicle' ada
          if (arguments is Map<String, dynamic> &&
              arguments.containsKey('vehicle')) {
            
            // Ambil seluruh objek vehicle dari argumen
            final vehicle = arguments['vehicle'] as Vehicle; 
            
            return ScheduleScreen(
              // Kirim data ke ScheduleScreen dengan tipe yang benar
              vehicleId: vehicle.vehicleId, // vehicleId dari model sudah int
              plateNumber: vehicle.plateNumber,
              vehicle: vehicle, // Kirim juga objek lengkapnya
            );
          }
          // Jika argumen tidak sesuai, tampilkan error
          return _buildErrorRoute("Data Kendaraan tidak valid untuk membuka Jadwal.");
        },
        NotificationListScreen.routeName: (context) =>
            const NotificationListScreen(),
        SparePartListScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic> && arguments.containsKey('vehicle')) {
            final vehicle = arguments['vehicle'] as Vehicle;
            return SparePartListScreen(vehicle: vehicle);
          }
          return _buildErrorRoute("Data Kendaraan tidak valid untuk membuka Katalog Part.");
        },
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        ContactUsScreen.routeName: (context) => const ContactUsScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }

  Widget _buildErrorRoute(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text("Error Navigasi")),
      body: Center(child: Text(message)),
    );
  }
}
