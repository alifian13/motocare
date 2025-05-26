// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_service.dart';
import '../services/location_service.dart';
import '../widgets/app_drawer.dart';
import '../models/user_data_model.dart'; // Impor UserData
import '../models/vehicle_model.dart';   // <-- IMPOR Vehicle DARI SINI
import 'notification_list_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'login_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();
  final LocationService _locationService = LocationService();

  UserData? _displayData;
  Vehicle? _primaryVehicle; // Tipe dari vehicle_model.dart
  bool _isLoading = true;
  String _userNameForAppBar = "Pengguna";
  String _appBarTitle = "MotoCare Dashboard";
  String? _currentVehicleIdForTracking;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initPrefsAndLoadData();
  }

  Future<void> _initPrefsAndLoadData() async {
    prefs = await SharedPreferences.getInstance();
    // Pastikan initializeNotifications ada di NotificationService
    await _notificationService.initializeNotifications();
    await _loadInitialDashboardData();
  }

  Future<void> _loadInitialDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    _userNameForAppBar = prefs.getString('user_name') ?? "Pengguna";
    String? userEmail = prefs.getString('user_email');
    String? userPhotoUrlFromPrefs = prefs.getString('user_photo_url');

    final List<Vehicle> vehicleList = await _vehicleService.getMyVehicles();
    Vehicle? fetchedPrimaryVehicle;

    if (vehicleList.isNotEmpty) {
        fetchedPrimaryVehicle = vehicleList.first;
        // vehicleId dari model adalah int, konversi ke String untuk SharedPreferences dan tracking
        _currentVehicleIdForTracking = fetchedPrimaryVehicle.vehicleId.toString();
        await prefs.setString('current_vehicle_id', _currentVehicleIdForTracking!);
        print("Kendaraan utama ditemukan: ${_currentVehicleIdForTracking}");
    } else {
        print("Tidak ada kendaraan ditemukan untuk pengguna ini.");
        _currentVehicleIdForTracking = null;
        await prefs.remove('current_vehicle_id');
    }

    if (mounted) {
      setState(() {
        _primaryVehicle = fetchedPrimaryVehicle; // Tipe Vehicle dari vehicle_model.dart
        _displayData = UserData.combine( // UserData.combine adalah metode statis
          {
            'name': _userNameForAppBar,
            'email': userEmail,
            'userPhotoUrl': userPhotoUrlFromPrefs
          },
          _primaryVehicle, // Tipe Vehicle dari vehicle_model.dart
        );
        _appBarTitle = _primaryVehicle?.model ?? 'MotoCare Dashboard';
        _isLoading = false;
      });

      bool isCurrentlyTracking = _locationService.isTrackingActive(); // Anda perlu menambahkan metode ini di LocationService
      if (_currentVehicleIdForTracking != null && !isCurrentlyTracking) {
        print("Memulai pelacakan untuk kendaraan: $_currentVehicleIdForTracking");
        _locationService.startTracking(context, _handleTripDetected);
      } else if (_currentVehicleIdForTracking == null && isCurrentlyTracking) {
         _locationService.stopTracking();
         print("Pelacakan dihentikan karena tidak ada kendaraan aktif.");
      } else if (_currentVehicleIdForTracking != null && isCurrentlyTracking) {
        print("Pelacakan sudah aktif untuk kendaraan: $_currentVehicleIdForTracking");
      } else {
        print("Tidak ada kendaraan aktif, pelacakan tidak dimulai.");
      }
    }
  }

  Future<void> _handleTripDetected(BuildContext dialogContext, double distanceKm, String vehicleId) async {
    if (!mounted) return;

    if (vehicleId != _currentVehicleIdForTracking) {
      print("Trip terdeteksi untuk vehicleId $vehicleId, tapi kendaraan aktif adalah $_currentVehicleIdForTracking. Mengabaikan.");
      return;
    }

    bool useMotor = await showDialog<bool>(
      context: dialogContext,
      builder: (BuildContext alertContext) => AlertDialog(
        title: const Text('Konfirmasi Perjalanan'),
        content: Text('Apakah Anda baru saja menggunakan motor (${_primaryVehicle?.plateNumber ?? vehicleId}) yang terdaftar untuk perjalanan sejauh ${distanceKm.toStringAsFixed(2)} km ini?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(alertContext).pop(false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.of(alertContext).pop(true), child: const Text('Ya')),
        ],
      ),
    ) ?? false;

    if (useMotor) {
      final tripData = {
        'distance_km': distanceKm,
      };
      final result = await _vehicleService.addTrip(vehicleId, tripData);
      if (mounted) {
        if (result['success']) {
          final newOdometerRaw = result['data']?['newOdometer'];
          print('Perjalanan berhasil dicatat via callback. Odometer baru: $newOdometerRaw');
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text('Perjalanan ${distanceKm.toStringAsFixed(2)} km berhasil dicatat! Odometer diperbarui.')),
          );

          if (newOdometerRaw != null && _primaryVehicle != null) {
            setState(() {
              int updatedOdometer;
              if (newOdometerRaw is int) {
                updatedOdometer = newOdometerRaw;
              } else if (newOdometerRaw is String) {
                updatedOdometer = int.tryParse(newOdometerRaw) ?? _primaryVehicle!.currentOdometer;
              } else if (newOdometerRaw is double) {
                updatedOdometer = newOdometerRaw.round();
              } else {
                updatedOdometer = _primaryVehicle!.currentOdometer;
              }

              _primaryVehicle!.currentOdometer = updatedOdometer; // Ini bisa di-set karena Vehicle dari vehicle_model.dart
              _displayData = UserData.combine(
                {
                  'name': _userNameForAppBar,
                  'email': prefs.getString('user_email'),
                  'userPhotoUrl': prefs.getString('user_photo_url')
                },
                _primaryVehicle,
              );
            });
          }
        } else {
          print('Gagal mencatat perjalanan via callback: ${result['message']}');
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal mencatat perjalanan')),
          );
        }
      }
    }
  }

  Future<void> _showManualOdometerUpdateDialog() async {
    if (_primaryVehicle == null || _currentVehicleIdForTracking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada kendaraan aktif untuk diupdate odometernya.')),
      );
      return;
    }

    final TextEditingController odometerInputController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    int? newOdometerValue = await showDialog<int?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Odometer Manual'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: odometerInputController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Odometer Baru (km)',
                hintText: 'Masukkan angka odometer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Odometer tidak boleh kosong';
                }
                final int? newOdo = int.tryParse(value);
                if (newOdo == null) {
                  return 'Masukkan angka yang valid';
                }
                if (newOdo <= (_primaryVehicle?.currentOdometer ?? 0)) {
                  return 'Odometer baru harus lebih besar dari saat ini (${_primaryVehicle?.currentOdometer ?? 0} km)';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(null),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(int.parse(odometerInputController.text));
                }
              },
            ),
          ],
        );
      },
    );

    if (newOdometerValue != null) {
      final result = await _vehicleService.updateOdometerManually(
          _currentVehicleIdForTracking!, newOdometerValue);

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Odometer berhasil diperbarui menjadi $newOdometerValue km.')),
          );
          setState(() {
            _primaryVehicle!.currentOdometer = newOdometerValue; // Bisa di-set
            _displayData = UserData.combine(
              {
                'name': _userNameForAppBar,
                'email': prefs.getString('user_email'),
                'userPhotoUrl': prefs.getString('user_photo_url')
              },
              _primaryVehicle,
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal update odometer.')),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    await _userService.logoutUser();
    _locationService.stopTracking();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (route) => false);
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Memuat...' : _appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, NotificationListScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _primaryVehicle == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.no_transfer_rounded, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Anda belum memiliki kendaraan terdaftar atau gagal memuat data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Tambah Kendaraan'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur tambah kendaraan belum ada.')),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loadInitialDashboardData,
                          child: const Text('Coba Lagi Memuat Data'),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInitialDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        _buildOdometerCard(),
                        const SizedBox(height: 20),
                        _buildServiceInfoCard(
                          title: "Oli Mesin",
                          lastServiceDate: _displayData?.formattedLastServiceDate ?? "N/A",
                          nextServiceInfo: "Penggantian Oli Selanjutnya",
                          daysRemaining: "Estimasi - Hari Lagi",
                          kmRemaining: "Estimasi - Km Lagi",
                          icon: Icons.opacity,
                        ),
                        const SizedBox(height: 30),
                        _buildNavigationGrid(),
                        const SizedBox(height: 20),
                        if (_currentVehicleIdForTracking != null)
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.location_on, color: Colors.green, size: 16),
                                        SizedBox(width: 8),
                                        Text("Pelacakan perjalanan aktif...", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic)),
                                    ],
                                ),
                            )
                        else
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.location_off, color: Colors.red, size: 16),
                                        SizedBox(width: 8),
                                        Text("Pelacakan perjalanan tidak aktif (tidak ada kendaraan).", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                                    ],
                                ),
                            ),
                      ],
                    ),
                  ),
                ),
    );
  }

  final String _baseImageUrl = "http://127.0.0.1:3000";

  Widget _buildProfileHeader() {
    if (_displayData == null || _primaryVehicle == null) return const SizedBox.shrink();
    String? userPhotoPath = _displayData!.userPhotoUrl;
    String? vehicleBrand = _primaryVehicle!.brand;
    String? vehicleModelString = _primaryVehicle!.model;
    String? vehicleLogoPath = _primaryVehicle!.logoUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: (userPhotoPath != null && userPhotoPath.isNotEmpty)
              ? NetworkImage(_baseImageUrl + userPhotoPath)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayData!.name ?? "Nama Pengguna",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                vehicleModelString,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (vehicleLogoPath != null && vehicleLogoPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.network(
              _baseImageUrl + vehicleLogoPath,
              height: 50,
              width: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.motorcycle, size: 30, color: Colors.grey.shade400);
              },
            ),
          )
        else if (vehicleBrand.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Chip(
                avatar: Icon(Icons.motorcycle, size: 18, color: Theme.of(context).primaryColorDark),
                label: Text(
                  vehicleBrand,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColorDark),
                ),
                backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.5),
              )),
      ],
    );
  }

  Widget _buildOdometerCard() {
    if (_primaryVehicle == null) return const SizedBox.shrink();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Odometer Saat Ini",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                TextButton.icon(
                  icon: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
                  label: Text("Update", style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: _showManualOdometerUpdateDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${_primaryVehicle!.currentOdometer} km",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard({
    required String title,
    required String lastServiceDate,
    required String nextServiceInfo,
    required String daysRemaining,
    required String kmRemaining,
    required IconData icon,
    String? status, // Tambahkan parameter status
  }) {
    Color cardColor = Colors.white;
    Color statusTextColor = Colors.grey;

    if (status != null) {
        if (status.toUpperCase() == "OVERDUE") {
            cardColor = Colors.red.shade50;
            statusTextColor = Colors.red.shade700;
        } else if (status.toUpperCase() == "UPCOMING") {
            cardColor = Colors.orange.shade50;
            statusTextColor = Colors.orange.shade700;
        }
    }

    return Card(
      elevation: 2,
      color: cardColor, // Warna kartu berdasarkan status
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text("Servis Terakhir Umum: $lastServiceDate", style: TextStyle(color: Colors.grey[600], fontSize: 12)), // Catatan: ini masih umum
            const Divider(height: 20, thickness: 1),
            Text(nextServiceInfo, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(daysRemaining, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusTextColor)),
                Text(kmRemaining, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildNavigationButton(
          icon: Icons.history,
          label: "History\nPerawatan",
          onTap: () {
            if (_primaryVehicle?.vehicleId != null) {
              Navigator.pushNamed(
                context,
                HistoryScreen.routeName,
                arguments: _primaryVehicle!.vehicleId.toString(), // Kirim String
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data kendaraan tidak tersedia untuk melihat riwayat.')),
              );
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.event_note,
          label: "Jadwal\nPerawatan",
          onTap: () {
            if (_primaryVehicle?.vehicleId != null) {
              Navigator.pushNamed(
                context,
                ScheduleScreen.routeName,
                arguments: _primaryVehicle!.vehicleId.toString(), // Kirim String
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data kendaraan tidak tersedia untuk melihat jadwal.')),
              );
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.person_outline,
          label: "Profil\nPengguna",
          onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
