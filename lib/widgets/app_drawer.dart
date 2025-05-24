import 'package:flutter/material.dart';
import '../services/user_service.dart'; // Untuk logout

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Anda bisa mengambil data pengguna di sini jika ingin menampilkan nama/email di header drawer
    // final userService = UserService(); // Contoh

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: const Text(
              "Nama Pengguna", // Ganti dengan data dinamis dari SharedPreferences/UserService
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text(
              "email@pengguna.com", // Ganti dengan data dinamis
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: const Icon(Icons.person, size: 50, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/home') {
                 Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman Profile (belum diimplementasi)')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('History Perawatan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Jadwal Perawatan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/schedule');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none_outlined),
            title: const Text('Daftar Notifikasi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman Contact Us (belum diimplementasi)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              final userService = UserService();
              await userService.clearUserData();
              Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}