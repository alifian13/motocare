import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Pastikan ini adalah tipe data yang digunakan LocationService
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/user_service.dart'; // Untuk mengambil data pengguna
// import 'package:sensors_plus/sensors_plus.dart'; // Jika masih digunakan
import '../ride_detection.dart'; // Import module ride_detection
import '../widgets/app_drawer.dart'; // Pastikan path ini benar
import '../models/user_data_model.dart'; // Buat model ini

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final RideDetection _rideDetection = RideDetection();

  UserData? _userData; // Menggunakan model UserData
  LatLng? _userLocation;
  String _rideStatus = "Memulai Aplikasi..."; // Status dari ride_detection

  @override
  void initState() {
    super.initState();
    _notificationService.initializeNotifications(); // Dari NotificationService Anda
    _loadInitialData();

    // Inisialisasi sensor untuk deteksi getaran dan kecepatan dari RideDetection Anda
    _rideDetection.initialize();
    _rideDetection.initSensors(); // Mungkin perlu stream subscription di sini
    _startRideDetectionUpdates(); // Untuk update status UI
  }

  Future<void> _loadInitialData() async {
    await _fetchUserData();
    await _loadUserLocation();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _userService.getUserData(); // Asumsi mengembalikan Map
      if (mounted) { // Cek jika widget masih terpasang
        setState(() {
          _userData = UserData.fromMap(data); // Konversi Map ke UserData model
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pengguna: $e')),
        );
      }
    }
  }

  Future<void> _loadUserLocation() async {
    LatLng? location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userLocation = location;
      });
    }
  }

  void _startRideDetectionUpdates() {
    // Anda mungkin perlu memodifikasi RideDetection untuk memberikan callback
    // atau stream status yang bisa di-listen di sini.
    // Contoh simulasi:
    // _rideDetection.statusStream.listen((status) {
    //   if (mounted) {
    //     setState(() {
    //       _rideStatus = status;
    //     });
    //   }
    // });
    // Untuk saat ini, kita panggil getCurrentSpeed secara periodik (bukan praktik terbaik)
    // Sebaiknya gunakan stream dari sensor.
    // Timer.periodic(const Duration(seconds: 10), (timer) {
    //   _rideDetection.getCurrentSpeed(); // Ini akan memicu notifikasi jika kondisi terpenuhi
    // });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?.vehicleModel ?? 'MotoCare Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Logika Logout - hapus data dari SharedPreferences
              await _userService.clearUserData(); // Tambahkan method ini di UserService
              Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Untuk pull-to-refresh data
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
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
                      lastServiceDate: _userData?.formattedLastServiceDate ?? "Belum ada data",
                      nextServiceInfo: "Penggantian Oli Selanjutnya",
                      // Logika estimasi perlu ditambahkan berdasarkan odometer atau tanggal
                      daysRemaining: "72 Hari Lagi (Contoh)",
                      kmRemaining: "1558 Km Lagi (Contoh)",
                      icon: Icons.opacity,
                    ),
                    const SizedBox(height: 20),
                     //_buildWorkshopCard(), // Anda bisa menambahkan ini jika ada data bengkel
                    // const SizedBox(height: 20),
                    // Text("Status Deteksi Perjalanan: $_rideStatus"), // Menampilkan status dari ride detection
                    // const SizedBox(height: 10),
                    // if (_userLocation != null)
                    //   Text('Lokasi Saat Ini: Lat: ${_userLocation!.latitude.toStringAsFixed(3)}, Lon: ${_userLocation!.longitude.toStringAsFixed(3)}'),
                    // const SizedBox(height: 30),
                    _buildNavigationGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueGrey[100],
          child: Text(
            _userData?.name.isNotEmpty == true ? _userData!.name[0].toUpperCase() : "M",
            style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userData?.name ?? "Nama Pengguna",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _userData?.vehicleModel ?? "Model Kendaraan", // Dari field 'motor' di UserService
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Bisa tambahkan logo kendaraan jika ada
        // Image.asset('assets/${_userData?.brand}_logo.png', height: 40),
      ],
    );
  }

  Widget _buildOdometerCard() {
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
              "${_userData?.currentOdometer ?? 0} km",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            // Tambahkan tombol untuk update odometer jika perlu
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(onPressed: () { /* Logika update odometer */ }, child: Text("Update")),
            // )
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
            Text("Terakhir: $lastServiceDate", style: TextStyle(color: Colors.grey[600])),
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

  // Widget _buildWorkshopCard() { ... } // Implementasi jika ada data bengkel

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
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
        _buildNavigationButton(
          icon: Icons.event_note,
          label: "Jadwal\nPerawatan",
          onTap: () => Navigator.pushNamed(context, '/schedule'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Untuk efek ripple yang sesuai card
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