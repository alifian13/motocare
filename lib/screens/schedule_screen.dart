// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Tidak digunakan jika vehicleId via argumen
import '../models/schedule_item.dart';
import '../services/vehicle_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String vehicleId; // <--- UBAH KE String

  const ScheduleScreen({super.key, required this.vehicleId});
  static const routeName = '/schedule';

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final VehicleService _vehicleService = VehicleService();
  late Future<List<ScheduleItem>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;
    // VehicleService.getSchedules mengharapkan String vehicleId, jadi widget.vehicleId sudah sesuai
    setState(() {
      _schedulesFuture = _vehicleService.getSchedules(widget.vehicleId);
    });
  }

  Future<void> _showServiceCompletionDialog(BuildContext parentContext, ScheduleItem schedule) async {
    final dialogFormKey = GlobalKey<FormState>();
    TextEditingController odometerController = TextEditingController();
    TextEditingController dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0,10));
    TextEditingController descriptionController = TextEditingController();
    TextEditingController workshopController = TextEditingController();
    TextEditingController costController = TextEditingController();
    String serviceType = schedule.itemName;

    return showDialog<void>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Konfirmasi Penyelesaian Servis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Servis: ${schedule.itemName}', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: odometerController,
                    decoration: const InputDecoration(labelText: 'Odometer saat Servis (km)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Odometer wajib diisi';
                      if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Tanggal Servis (YYYY-MM-DD)', border: OutlineInputBorder()),
                    readOnly: true,
                    onTap: () async {
                      FocusScope.of(dialogContext).requestFocus(FocusNode());
                      DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now());
                      if (picked != null) {
                        dateController.text = picked.toIso8601String().substring(0, 10);
                      }
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Tanggal wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Catatan Tambahan (Opsional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                   const SizedBox(height: 10),
                  TextFormField(
                    controller: workshopController,
                    decoration: const InputDecoration(labelText: 'Nama Bengkel (Opsional)', border: OutlineInputBorder()),
                  ),
                   const SizedBox(height: 10),
                  TextFormField(
                    controller: costController,
                    decoration: const InputDecoration(labelText: 'Biaya Servis (Opsional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Simpan & Selesaikan'),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  dialogFormKey.currentState!.save();
                  final serviceData = {
                    'service_date': dateController.text,
                    'odometer_at_service': int.parse(odometerController.text),
                    'service_types': [serviceType],
                    'completed_schedule_ids': [schedule.scheduleId],
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'workshop_name': workshopController.text.isEmpty ? null : workshopController.text,
                    'cost': costController.text.isEmpty ? null : double.tryParse(costController.text),
                  };
                  Navigator.of(dialogContext).pop();
                  final result = await _vehicleService.addServiceHistory(widget.vehicleId, serviceData); // widget.vehicleId sudah String

                  if (mounted) {
                    if (result['success']) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(content: Text('Servis berhasil dicatat dan jadwal diperbarui!'), backgroundColor: Colors.green),
                      );
                      _loadSchedules();
                    } else {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Gagal mencatat servis.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Perawatan Kendaraan'),
      ),
      body: FutureBuilder<List<ScheduleItem>>(
        future: _schedulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center( /* ... UI Error ... */ );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center( /* ... UI Kosong ... */ );
          }
          final schedules = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadSchedules,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                Color statusColor = Colors.grey.shade300;
                IconData statusIcon = Icons.schedule;
                bool showCompleteButton = false;

                switch (schedule.status?.toUpperCase()) {
                  case 'UPCOMING':
                    statusColor = Colors.orange.shade100;
                    statusIcon = Icons.notification_important_outlined;
                    showCompleteButton = true;
                    break;
                  case 'OVERDUE':
                    statusColor = Colors.red.shade100;
                    statusIcon = Icons.error_outline;
                    showCompleteButton = true;
                    break;
                  case 'PENDING':
                    statusColor = Colors.blue.shade50;
                    statusIcon = Icons.hourglass_empty_outlined;
                    break;
                  case 'COMPLETED':
                    statusColor = Colors.green.shade100;
                    statusIcon = Icons.check_circle_outline;
                    break;
                }

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: Icon(statusIcon, color: Theme.of(context).primaryColorDark),
                    ),
                    title: Text(schedule.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Berikutnya di: ${schedule.nextDueOdometer} km'),
                        Text("Status: ${schedule.status ?? 'N/A'}", style: TextStyle(fontWeight: FontWeight.w500, color: schedule.status?.toUpperCase() == 'OVERDUE' ? Colors.red.shade700 : Colors.black87)),
                         if (schedule.description != null && schedule.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text("Catatan: ${schedule.description}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ),
                      ],
                    ),
                    trailing: showCompleteButton
                        ? ElevatedButton(
                            onPressed: () => _showServiceCompletionDialog(context, schedule),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12)
                            ),
                            child: const Text('Selesai'),
                          )
                        : (schedule.status?.toUpperCase() == 'COMPLETED'
                            ? Icon(Icons.check, color: Colors.green.shade700)
                            : null),
                    onTap: () {
                      print("Tapped on ${schedule.itemName}");
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSchedules,
        tooltip: 'Refresh Jadwal',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
