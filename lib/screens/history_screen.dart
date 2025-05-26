// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../models/service_history_item.dart';
import '../services/vehicle_service.dart';

class HistoryScreen extends StatefulWidget {
  final int vehicleId; // Menerima int
  const HistoryScreen({super.key, required this.vehicleId});
  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final VehicleService _vehicleService = VehicleService();
  late Future<List<ServiceHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      // VehicleService.getServiceHistory mengharapkan String, jadi konversi widget.vehicleId
      _historyFuture = _vehicleService.getServiceHistory(widget.vehicleId.toString());
    });
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
        title: const Text('Riwayat Perawatan'),
      ),
      body: FutureBuilder<List<ServiceHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _loadHistory, child: const Text('Coba Lagi'))
                    ],
                  ),
                )
              );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_toggle_off_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Belum ada riwayat perawatan untuk kendaraan ini.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                      ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Riwayat Servis Manual'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur tambah riwayat manual belum terhubung.')),
                        );
                      },
                    ),
                  ],
                ));
          }
          final historyItems = snapshot.data!;
          return RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return Card(
                    elevation: 2.0,
                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.7),
                        child: Icon(_getIconForServiceType(item.serviceType), color: Theme.of(context).primaryColorDark),
                      ),
                      title: Text(item.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tanggal: ${item.formattedServiceDate ?? 'N/A'}"),
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
                      onTap: () { /* detail halaman service */ },
                    ),
                  );
                },
              ),
            );
        },
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _loadHistory,
        tooltip: 'Refresh Riwayat',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
