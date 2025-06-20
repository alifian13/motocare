import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_history_item.dart';
import '../services/vehicle_service.dart';

class HistoryScreen extends StatefulWidget {
  final int vehicleId;
  final String? plateNumber;

  const HistoryScreen({super.key, required this.vehicleId, this.plateNumber});
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
      _historyFuture = _vehicleService.getServiceHistory(widget.vehicleId.toString());
    });
  }

  IconData _getIconForServiceType(String serviceType) {
    String typeLower = serviceType.toLowerCase();
    if (typeLower.contains('oli mesin')) {
      return Icons.opacity_outlined;
    } else if (typeLower.contains('oli gardan')) {
      return Icons.water_drop_outlined;
    } else if (typeLower.contains('cvt') || typeLower.contains('mesin')) {
      return Icons.settings_applications_outlined;
    } else if (typeLower.contains('ban')) {
      return Icons.tire_repair_outlined;
    } else if (typeLower.contains('rem')) {
      return Icons.car_repair;
    } else if (typeLower.contains('kelistrikan') || typeLower.contains('aki')) {
      return Icons.electrical_services_outlined;
    }
    return Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat ${widget.plateNumber ?? ''}'),
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
                    Icon(Icons.history_toggle_off_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text("Belum ada riwayat perawatan.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 20),
                      ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Riwayat Manual'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur tambah riwayat manual belum diimplementasikan.')),
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
                padding: const EdgeInsets.all(12.0),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.5),
                        child: Icon(_getIconForServiceType(item.serviceType), color: Theme.of(context).primaryColorDark, size: 24),
                      ),
                      title: Text(item.serviceType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text("Tanggal: ${item.formattedServiceDate}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          Text("Odometer: ${NumberFormat.decimalPattern('id_ID').format(item.odometerAtService)} km", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          if (item.workshopName != null && item.workshopName!.isNotEmpty)
                            Text("Bengkel: ${item.workshopName}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          if (item.description != null && item.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Text("Catatan: ${item.description}", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                            ),
                          if (item.cost != null && item.cost! > 0)
                            Text("Biaya: Rp ${NumberFormat.decimalPattern('id_ID').format(item.cost)}", style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500)),
                        ],
                      ),
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
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
