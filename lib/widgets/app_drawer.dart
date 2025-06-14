// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:motocare/screens/settings_screen.dart'; //
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/contact_us_screen.dart';
import '../screens/profile_screen.dart';
import '../services/user_service.dart'; // Untuk konstanta kunci dan logout
// Impor layar yang akan dinavigasi
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = "Nama Pengguna";
  String _userEmail = "email@pengguna.com";
  String? _userPhotoUrl;
  // Sesuaikan dengan _baseImageUrl di home_screen.dart
  final String _baseImageUrl = "https://motocares.my.id";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName =
            prefs.getString(UserService.prefUserName) ?? "Nama Pengguna";
        _userEmail =
            prefs.getString(UserService.prefUserEmail) ?? "email@pengguna.com";
        _userPhotoUrl = prefs.getString(UserService.prefUserPhotoUrl);
      });
    }
  }

  // Helper untuk navigasi yang memerlukan vehicleId
  void _navigateToVehicleSpecificScreen(String routeName) async {
    Navigator.pop(context); // Tutup drawer dulu
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final vehicleIdString = prefs.getString(UserService.prefCurrentVehicleId);

    if (vehicleIdString != null) {
      Map<String, dynamic> arguments = {};
      if (routeName == HistoryScreen.routeName) {
        arguments['vehicleId'] =
            int.tryParse(vehicleIdString); // HistoryScreen butuh int
      } else if (routeName == ScheduleScreen.routeName) {
        arguments['vehicleId'] = vehicleIdString; // ScheduleScreen butuh String
      }

      if (arguments['vehicleId'] != null) {
        Navigator.pushNamed(context, routeName, arguments: arguments);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Kendaraan tidak valid.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Pilih kendaraan terlebih dahulu di Beranda untuk mengakses menu ini.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    ImageProvider<Object> avatarImage;
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      if (_userPhotoUrl!.startsWith('http')) {
        avatarImage = NetworkImage(_userPhotoUrl!);
      } else {
        avatarImage = NetworkImage(_baseImageUrl + _userPhotoUrl!);
      }
    } else {
      avatarImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              _userName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
            ),
            accountEmail: Text(
              _userEmail,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              backgroundImage: avatarImage,
              onBackgroundImageError: (_, __) {
                if (mounted) {
                  setState(() {
                    // Fallback jika NetworkImage gagal
                    avatarImage =
                        const AssetImage('assets/images/default_avatar.png');
                  });
                }
              },
              child: (_userPhotoUrl == null || _userPhotoUrl!.isEmpty) &&
                      _userName.isNotEmpty &&
                      _userName != "Nama Pengguna"
                  ? Text(
                      _userName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 36,
                          color: Theme.of(context).primaryColorDark),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            otherAccountsPictures: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined,
                    color: Colors.white70, size: 20),
                onPressed: _loadUserData,
                tooltip: 'Refresh data pengguna',
              )
            ],
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, size: 22),
            title: const Text('Beranda', style: TextStyle(fontSize: 14.5)),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name !=
                  HomeScreen.routeName) {
                Navigator.pushNamedAndRemoveUntil(
                    context, HomeScreen.routeName, (route) => false);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, size: 22),
            title: const Text('Profil Saya', style: TextStyle(fontSize: 14.5)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),
          const Divider(height: 1, thickness: 0.5),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined, size: 22),
            title: const Text('Hubungi Kami', style: TextStyle(fontSize: 14.5)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ContactUsScreen.routeName);
            },
          ),
          const Divider(height: 1, thickness: 0.5),
          ListTile(
            leading: Icon(Icons.logout_outlined,
                color: Colors.red.shade600, size: 22),
            title: Text('Logout',
                style: TextStyle(color: Colors.red.shade600, fontSize: 14.5)),
            onTap: () async {
              Navigator.pop(context);
              await userService.logoutUser();
              Navigator.pushNamedAndRemoveUntil(
                  context, LoginScreen.routeName, (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
