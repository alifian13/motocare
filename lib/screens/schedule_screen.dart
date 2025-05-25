// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import '../models/schedule_item.dart'; // Model baru
import '../services/vehicle_service.dart';
// import '../models/user_data_model.dart'; // Jika perlu vehicleId dari sini

class ScheduleScreen extends StatefulWidget {
  final int vehicleId; // ID kendaraan yang akan ditampilkan jadwalnya

  const ScheduleScreen({super.key, required this.vehicleId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<ScheduleItem> _scheduleItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMaintenanceSchedules();
  }

  Future<void> _fetchMaintenanceSchedules() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _vehicleService.getMaintenanceSchedules(widget.vehicleId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      if (result['data'] is List) {
        List<dynamic> scheduleListJson = result['data'] as List<dynamic>;
        setState(() {
          _scheduleItems = scheduleListJson
              .map((json) {
                if (json is Map<String, dynamic>) {
                  return ScheduleItem.fromJson(json);
                }
                return null;
              })
              .whereType<ScheduleItem>()
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Format data jadwal tidak sesuai dari server.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat jadwal perawatan.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Perawatan'),
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
                        ElevatedButton(onPressed: _fetchMaintenanceSchedules, child: const Text('Coba Lagi'))
                      ],
                    ),
                  ))
              : _scheduleItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text("Belum ada jadwal perawatan untuk kendaraan ini.", textAlign: TextAlign.center),
                           const SizedBox(height: 10),
                           ElevatedButton.icon(
                            icon: const Icon(Icons.add_alarm_outlined),
                            label: const Text('Tambah Jadwal Manual'),
                            onPressed: () {
                              // TODO: Navigasi ke halaman tambah jadwal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur tambah jadwal belum ada.')),
                              );
                            },
                          ),
                        ],
                      ))
                  : RefreshIndicator(
                      onRefresh: _fetchMaintenanceSchedules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: _scheduleItems.length,
                        itemBuilder: (context, index) {
                          final item = _scheduleItems[index];
                          return Card(
                            elevation: 2.0,
                            color: item.getStatusColor(), // Warna berdasarkan status
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Icon(item.getStatusIcon(), color: Theme.of(context).primaryColorDark),
                              ),
                              title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Jadwal: ${item.displayDueDate}"),
                                  if (item.description != null && item.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text("Catatan: ${item.description}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                    ),
                                  Text("Status: ${item.status}", style: TextStyle(fontWeight: FontWeight.w500, color: item.status.toUpperCase() == 'OVERDUE' ? Colors.red : Colors.black87)),
                                ],
                              ),
                              // trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // Opsional
                              onTap: () {
                                // TODO: Aksi saat item jadwal di-tap (misal, tandai selesai, edit)
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}