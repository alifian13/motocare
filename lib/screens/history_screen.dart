// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../models/service_history_item.dart'; // Model baru yang benar
import '../services/vehicle_service.dart';
// import '../models/user_data_model.dart'; // Tidak perlu jika vehicleId sudah didapat

// HAPUS BAGIAN INI KARENA TIDAK DIGUNAKAN LAGI:
// List<ServiceItem> dummyHistoryItems = [
//   ServiceItem(title: "Service CVT", date: "12/01/2025", odometer: "63147 km", plateNumber: "K 5036 AZF", icon: Icons.settings_applications_outlined),
//   ServiceItem(title: "Pergantian Oli", date: "02/12/2024", odometer: "60100 km", plateNumber: "K 5036 AZF", icon: Icons.opacity_outlined),
// ];
// HAPUS JUGA IMPORT UNTUK ServiceItem JIKA HANYA UNTUK DUMMY DI ATAS:
// import '../models/service_item.dart';

class HistoryScreen extends StatefulWidget {
  final int vehicleId;

  const HistoryScreen({super.key, required this.vehicleId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<ServiceHistoryItem> _historyItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServiceHistory();
  }

  Future<void> _fetchServiceHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _vehicleService.getServiceHistory(widget.vehicleId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      if (result['data'] is List) { // Tambahan pengecekan tipe data
        List<dynamic> historyListJson = result['data'] as List<dynamic>;
        setState(() {
          _historyItems = historyListJson
              .map((json) {
                if (json is Map<String, dynamic>) { // Pastikan setiap item adalah Map
                  return ServiceHistoryItem.fromJson(json);
                }
                return null; // Atau throw error jika format tidak sesuai
              })
              .whereType<ServiceHistoryItem>() // Hanya ambil item yang berhasil diparsing
              .toList();
          _isLoading = false;
        });
      } else {
         setState(() {
          _errorMessage = 'Format data riwayat tidak sesuai dari server.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat riwayat servis.';
        _isLoading = false;
      });
    }
  }

  IconData _getIconForServiceType(String serviceType) {
    String typeLower = serviceType.toLowerCase();
    if (typeLower.contains('oli')) {
      return Icons.opacity_outlined;
    } else if (typeLower.contains('cvt') || typeLower.contains('mesin')) {
      return Icons.settings_applications_outlined;
    } else if (typeLower.contains('ban')) {
      return Icons.tire_repair_outlined;
    } else if (typeLower.contains('rem')) {
      return Icons.car_repair_outlined;
    }
    return Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Perawatan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _fetchServiceHistory, child: const Text('Coba Lagi'))
                      ],
                    ),
                  ))
              : _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text("Belum ada history perawatan untuk kendaraan ini.", textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                           ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Tambah Riwayat Servis'),
                            onPressed: () {
                              // TODO: Navigasi ke halaman tambah riwayat servis
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur tambah riwayat belum ada.')),
                              );
                            },
                          ),
                        ],
                      )
                    )
                  : RefreshIndicator( // Tambahkan RefreshIndicator
                      onRefresh: _fetchServiceHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: _historyItems.length,
                        itemBuilder: (context, index) {
                          final item = _historyItems[index];
                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.7),
                                child: Icon(_getIconForServiceType(item.serviceType), color: Theme.of(context).primaryColorDark),
                              ),
                              title: Text(item.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Tanggal: ${item.formattedServiceDate}"),
                                  Text("Odometer: ${item.odometerAtService} km"),
                                  if (item.workshopName != null && item.workshopName!.isNotEmpty)
                                    Text("Bengkel: ${item.workshopName}"),
                                  if (item.description != null && item.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text("Deskripsi: ${item.description}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    ),
                                  if (item.cost != null && item.cost! > 0)
                                    Text("Biaya: Rp ${item.cost!.toStringAsFixed(0)}", style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                ],
                              ),
                              // trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Opsional
                              onTap: () {
                                // TODO: Halaman detail riwayat servis
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}