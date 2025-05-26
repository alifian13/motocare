// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/contact_us_screen.dart';
import '../services/user_service.dart'; // Untuk logout

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = "Nama Pengguna";
  String _userEmail = "email@pengguna.com";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) { // Pastikan widget masih ada di tree
      setState(() {
        _userName = prefs.getString('userName') ?? "Nama Pengguna";
        _userEmail = prefs.getString('userEmail') ?? "email@pengguna.com";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService(); // Instance untuk logout

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              _userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              _userEmail,
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: _userName.isNotEmpty
                  ? Text(
                      _userName[0].toUpperCase(), // Ambil huruf pertama dari nama
                      style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
                    )
                  : Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile'); // Arahkan ke /profile
            },
          ),
          // Hapus menu Dashboard, History, Jadwal, Notifikasi
          // const Divider(), // Divider bisa ditambahkan jika ingin ada pemisah
          ListTile(
            leading: const Icon(Icons.contact_support_outlined),
            title: const Text('Contact Us'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.pushNamed(context, ContactUsScreen.routeName);
            },
          ),
          const Divider(), // Pemisah sebelum logout
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context); // Tutup drawer dulu
              await userService.logoutUser(); // Panggil metode logout dari service
              // Arahkan ke halaman login dan hapus semua route sebelumnya
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}