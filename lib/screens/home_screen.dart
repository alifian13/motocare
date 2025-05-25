// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/vehicle_service.dart';
import '../widgets/app_drawer.dart';
import '../models/user_data_model.dart'; // Pastikan model UserData dan Vehicle ada di sini

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();

  UserData? _displayData;
  Vehicle? _primaryVehicle; // Jadikan ini state variable untuk data kendaraan utama
  bool _isLoading = true;
  String _userNameForAppBar = "Pengguna"; // Untuk AppBar, bisa juga dari _displayData
  String _appBarTitle = "MotoCare Dashboard";

  @override
  void initState() {
    super.initState();
    _notificationService.initializeNotifications();
    _loadInitialDashboardData();
  }

  Future<void> _loadInitialDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userNameForAppBar = prefs.getString('userName') ?? "Pengguna";
    String? userEmail = prefs.getString('userEmail');
    String? userPhotoUrlFromPrefs = prefs.getString('userPhotoUrl');

    final vehicleResult = await _vehicleService.getMyVehicles();
    Vehicle? fetchedPrimaryVehicle; // Variabel temporary

    if (vehicleResult['success'] == true && vehicleResult['data'] != null) {
      if (vehicleResult['data'] is List) {
        List<dynamic> vehicleListJson = vehicleResult['data'] as List<dynamic>;
        if (vehicleListJson.isNotEmpty) {
          if (vehicleListJson.first is Map<String, dynamic>) {
            fetchedPrimaryVehicle = Vehicle.fromJson(vehicleListJson.first as Map<String, dynamic>);
          } else {
            print("Error: Format data kendaraan pertama tidak sesuai (bukan Map).");
          }
        }
      } else {
        print("Error: Data kendaraan dari API bukan berupa List.");
      }
    }

    if (mounted) {
      setState(() {
        _primaryVehicle = fetchedPrimaryVehicle; // Update state _primaryVehicle
        _displayData = UserData.combine(
          {'name': _userNameForAppBar, 'email': userEmail, 'userPhotoUrl': userPhotoUrlFromPrefs},
          _primaryVehicle,
        );
        _appBarTitle = _primaryVehicle?.model ?? 'MotoCare Dashboard';
        _isLoading = false;
      });
    }

    if (vehicleResult['success'] == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vehicleResult['message'] ?? 'Gagal memuat data kendaraan.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await _userService.logoutUser();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Memuat...' : _appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _primaryVehicle == null // Gunakan _primaryVehicle untuk cek data kendaraan
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.no_transfer_rounded, size: 60, color: Colors.grey), // Icon yang lebih relevan
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
                            // TODO: Navigasi ke halaman tambah kendaraan
                            // Navigator.pushNamed(context, '/add-vehicle').then((_) => _loadInitialDashboardData());
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
              : RefreshIndicator( // Hanya tampilkan jika _primaryVehicle tidak null
                  onRefresh: _loadInitialDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Widget anak sekarang bisa lebih aman menggunakan _displayData
                        // karena bagian ini hanya dirender jika _primaryVehicle (dan _displayData) ada.
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        _buildOdometerCard(),
                        const SizedBox(height: 20),
                        _buildServiceInfoCard(
                          title: "Perawatan Terakhir",
                          lastServiceDate: _displayData!.formattedLastServiceDate, // ! aman di sini
                          nextServiceInfo: "Penggantian Oli Selanjutnya", // Perlu logika
                          daysRemaining: "Estimasi 72 Hari Lagi", // Perlu logika
                          kmRemaining: "Estimasi 1558 Km Lagi",   // Perlu logika
                          icon: Icons.opacity,
                        ),
                        const SizedBox(height: 30),
                        _buildNavigationGrid(),
                      ],
                    ),
                  ),
                ),
    );
  }
final String _baseImageUrl = "http://127.0.0.1:3000";
  Widget _buildProfileHeader() {
    // _displayData dijamin tidak null di sini karena logika di build()
    String? userPhotoPath = _displayData?.userPhotoUrl; // Asumsi Anda menambahkan userPhotoUrl ke UserData
    String? vehicleLogoPath = _displayData?.vehicleLogoUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300, // Warna fallback jika tidak ada gambar
          backgroundImage: (userPhotoPath != null && userPhotoPath.isNotEmpty)
              ? NetworkImage(_baseImageUrl + userPhotoPath) // Muat dari network jika ada URL
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider, // Gambar default lokal
          // Jika Anda ingin placeholder berupa ikon jika tidak ada gambar:
          // child: (userPhotoPath == null || userPhotoPath.isEmpty)
          //     ? Icon(Icons.person, size: 30, color: Colors.grey.shade700)
          //     : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayData?.name ?? "Nama Pengguna",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _displayData?.vehicleModel ?? "Model Kendaraan",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Tampilkan Logo/Emblem Kendaraan
        if (vehicleLogoPath != null && vehicleLogoPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.network(
              _baseImageUrl + vehicleLogoPath,
              // --- UBAH UKURAN DI SINI ---
              height: 100, // Misalnya, perbesar menjadi tinggi 50 (sebelumnya 35)
              width: 100,  // Anda juga bisa mengatur width jika ingin ukuran yang pasti
                           // Atau biarkan width null agar mengikuti rasio aspek gambar berdasarkan height
              fit: BoxFit.contain, // Memastikan gambar tetap dalam batas dan tidak terpotong aneh
              // --- BATAS PERUBAHAN UKURAN ---
              errorBuilder: (context, error, stackTrace) {
                print("Error loading vehicle logo: $error");
                return Icon(Icons.motorcycle, size: 30, color: Colors.grey.shade400); // Sesuaikan ukuran ikon error juga jika perlu
              },
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 100, // Sesuaikan dengan height di atas
                  width: 100,  // Sesuaikan dengan width di atas
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          )
        else if (_primaryVehicle != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Chip(
              avatar: Icon(Icons.motorcycle, size: 18, color: Theme.of(context).primaryColorDark), // Bisa perbesar sedikit
              label: Text(
                _displayData?.brand ?? 'Motor',
                style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColorDark), // Bisa perbesar sedikit font
              ),
              backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Sesuaikan padding
              labelPadding: const EdgeInsets.only(left: 2.0, right: 4.0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          ),
      ],
    );
  }

  Widget _buildOdometerCard() {
    // _displayData dijamin tidak null di sini
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Odometer Saat Ini",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(
              "${_displayData!.currentOdometer} km",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            // TODO: Tombol update odometer
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
  }) {
    return Card(
      // ... (Implementasi widget ini sama seperti sebelumnya, aman karena _displayData sudah dipastikan)
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
            Text("Servis Terakhir: $lastServiceDate", style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 20, thickness: 1),
            Text(nextServiceInfo, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(daysRemaining, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                Text(kmRemaining, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
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
            if (_primaryVehicle != null && _primaryVehicle!.vehicleId != null) {
              Navigator.pushNamed(
                context,
                '/history',
                arguments: _primaryVehicle!.vehicleId,
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
          onTap: () { // PERBAIKI BAGIAN INI
            if (_primaryVehicle != null && _primaryVehicle!.vehicleId != null) {
              Navigator.pushNamed(
                context,
                '/schedule', // Pastikan nama route sudah benar
                arguments: _primaryVehicle!.vehicleId, // KIRIM vehicleId
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data kendaraan tidak tersedia untuk melihat jadwal.')),
              );
            }
          },
        ),
        _buildNavigationButton(
          icon: Icons.notifications_active,
          label: "Daftar\nNotifikasi",
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
      ],
    );
  }

  Widget _buildNavigationButton({required IconData icon, required String label, required VoidCallback onTap}) {
    // ... (Implementasi widget ini sama seperti sebelumnya)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: 2,
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