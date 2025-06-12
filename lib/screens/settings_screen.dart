import 'package:flutter/material.dart';
import 'package:motocare/services/background_tracking_service.dart';
import 'package:motocare/services/user_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTrackingEnabled = false;
  bool _isLoading = true;
  final BackgroundTrackingService _trackingService = BackgroundTrackingService.instance;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTrackingEnabled = prefs.getBool('isBackgroundTrackingActive') ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTracking(bool value) async {
    setState(() => _isLoading = true);

    if (value) {
      final prefs = await SharedPreferences.getInstance();
      final vehicleIdString = prefs.getString(UserService.prefCurrentVehicleId);

      if (vehicleIdString == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih kendaraan dahulu di Beranda.'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isLoading = false);
        return;
      }
      final vehicleId = int.tryParse(vehicleIdString);
      if (vehicleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ID kendaraan tidak valid.'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isLoading = false);
        return;
      }
      
      var status = await Permission.locationAlways.request();
      if (status.isGranted) {
        await _trackingService.startService(vehicleId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pelacakan Latar Belakang Diaktifkan.'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin lokasi di latar belakang dibutuhkan.'),
        ));
        value = false;
      }
    } else {
      await _trackingService.stopService();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pelacakan Latar Belakang Dinonaktifkan.'),
      ));
    }

    if (mounted) {
      setState(() {
        _isTrackingEnabled = value;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Pelacakan Odometer Otomatis'),
            subtitle: const Text('Fitur ini akan terus berjalan di latar belakang untuk mencatat perjalanan Anda secara otomatis.'),
            value: _isTrackingEnabled,
            onChanged: _isLoading ? null : _toggleTracking,
            activeColor: Theme.of(context).primaryColor,
            secondary: Icon(Icons.location_on_outlined,
                color: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }
}