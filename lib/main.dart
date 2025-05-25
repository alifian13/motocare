import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/profile_screen.dart';

// Import semua screen Anda
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/history_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/notification_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Cek apakah token ada untuk menentukan status login
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
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue[700]!),
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
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          // Pastikan arguments adalah int atau handle jika null/salah tipe
          if (arguments is int) {
            return HistoryScreen(vehicleId: arguments);
          }
          // Fallback jika argumen tidak ada atau salah tipe
          // Anda bisa mengarahkan ke halaman error atau halaman utama dengan pesan
          return Scaffold(
              appBar: AppBar(title: Text("Error")),
              body: Center(child: Text("ID Kendaraan tidak valid atau tidak ditemukan untuk History.")));
        },
        '/schedule': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is int) {
            return ScheduleScreen(vehicleId: arguments);
          }
          // Fallback
          return Scaffold(
              appBar: AppBar(title: Text("Error")),
              body: Center(child: Text("ID Kendaraan tidak valid atau tidak ditemukan untuk Jadwal.")));
        },
        '/notifications': (context) => const NotificationListScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}