import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk cek status login (simulasi)

// Ganti path import sesuai struktur folder Anda
// Jika screens ada di lib/screens/, services di lib/services/, dll.
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/history_screen.dart'; // Buat file ini jika belum ada
import 'screens/schedule_screen.dart'; // Buat file ini jika belum ada
import 'screens/notification_list_screen.dart'; // Buat file ini jika belum ada
// import 'services/user_service.dart'; // Jika diperlukan untuk cek login awal

void main() async {
  // Pastikan Flutter binding sudah diinisialisasi sebelum menggunakan SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  // Simulasi pengecekan status login
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getString('email') != null && prefs.getString('email')!.isNotEmpty;

  runApp(MotorApp(isLoggedIn: isLoggedIn));
}

class MotorApp extends StatelessWidget {
  final bool isLoggedIn;
  const MotorApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoCare', // Judul aplikasi sesuai desain
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
        cardTheme: CardTheme(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
        ),
        textTheme: TextTheme( // Styling teks dasar
          bodyLarge: TextStyle(color: Colors.grey[800]),
          bodyMedium: TextStyle(color: Colors.grey[700]),
          titleMedium: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        )
      ),
      initialRoute: isLoggedIn ? '/home' : '/register', // Arahkan berdasarkan status login
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/notifications': (context) => const NotificationListScreen(),
        // Tambahkan rute lain jika diperlukan, misal '/profile', '/contact-us'
      },
    );
  }
}