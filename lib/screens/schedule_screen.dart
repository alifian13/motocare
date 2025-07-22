import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/schedule_item.dart';
import '../services/vehicle_service.dart';
import 'spare_part_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final String vehicleId;
  final String? plateNumber;

  const ScheduleScreen({super.key, required this.vehicleId, this.plateNumber});
  static const routeName = '/schedule';

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final VehicleService _vehicleService = VehicleService();
  late Future<List<ScheduleItem>> _schedulesFuture;

  final List<String> _replaceablePartServices = const [
    'Ganti Roller',
    'Ganti V-belt',
    'Ganti Slider',
    'Ganti Kampas Ganda',
    'Ganti Per CVT',
    'Ganti Per Sentrifugal',
    'Ganti Mangkok Ganda',
    'Ganti Rumah Roller'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() {
      _schedulesFuture = _vehicleService.getSchedules(widget.vehicleId);
    });
  }

  Future<void> _launchPurchaseLink() async {
    final Uri url = Uri.parse('https://s.shopee.co.id/LcQDiqTIn');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link.')),
        );
      }
    }
  }

  Future<void> _showServiceCompletionDialog(
      BuildContext parentContext, ScheduleItem schedule) async {
    final dialogFormKey = GlobalKey<FormState>();
    TextEditingController odometerController = TextEditingController();
    TextEditingController dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    TextEditingController descriptionController = TextEditingController();
    TextEditingController workshopController = TextEditingController();
    TextEditingController costController = TextEditingController();
    String serviceType = schedule.itemName;

    return showDialog<void>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Penyelesaian Servis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Servis: ${schedule.itemName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: odometerController,
                    decoration: const InputDecoration(
                        labelText: 'Odometer saat Servis (km)',
                        border: OutlineInputBorder(),
                        hintText: 'Contoh: 15000'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Odometer wajib diisi';
                      if (int.tryParse(value) == null)
                        return 'Masukkan angka yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                        labelText: 'Tanggal Servis',
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD'),
                    readOnly: true,
                    onTap: () async {
                      FocusScope.of(dialogContext).requestFocus(FocusNode());
                      DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 1)));
                      if (picked != null) {
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Tanggal wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan (Opsional)',
                        border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: workshopController,
                    decoration: const InputDecoration(
                        labelText: 'Nama Bengkel (Opsional)',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: costController,
                    decoration: const InputDecoration(
                        labelText: 'Biaya Servis (Opsional)',
                        border: OutlineInputBorder(),
                        prefixText: "Rp "),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Simpan & Selesaikan'),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  dialogFormKey.currentState!.save();
                  final serviceData = {
                    'service_date': dateController.text,
                    'odometer_at_service': int.parse(odometerController.text),
                    'service_types': [serviceType],
                    'completed_schedule_ids': [schedule.scheduleId],
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'workshop_name': workshopController.text.isEmpty
                        ? null
                        : workshopController.text,
                    'cost': costController.text.isEmpty
                        ? null
                        : double.tryParse(
                            costController.text.replaceAll('.', '')),
                  };
                  Navigator.of(dialogContext).pop();

                  final result = await _vehicleService.addServiceHistory(
                      widget.vehicleId, serviceData);

                  if (mounted) {
                    if (result['success']) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Servis berhasil dicatat dan jadwal diperbarui!'),
                            backgroundColor: Colors.green),
                      );
                      _loadSchedules();
                    } else {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                            content: Text(
                                result['message'] ?? 'Gagal mencatat servis.'),
                            backgroundColor: Colors.red),
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
        title: Text('Jadwal Perawatan ${widget.plateNumber ?? ''}'),
      ),
      body: FutureBuilder<List<ScheduleItem>>(
        future: _schedulesFuture,
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
                  Text('Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: _loadSchedules, child: const Text('Coba Lagi'))
                ],
              ),
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("Tidak ada jadwal perawatan saat ini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  "Jadwal akan muncul otomatis berdasarkan penggunaan.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ));
          }
          final schedules = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadSchedules,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                final bool isReplaceable =
                    _replaceablePartServices.contains(schedule.itemName);
                // Asumsi `vehicleCode` ada di model `ScheduleItem` yang didapat dari backend
                // Jika tidak, Anda perlu mengambil data vehicle terlebih dahulu.
                final bool canShowSparePart = isReplaceable;
                Color statusColor = schedule.getStatusColor();
                IconData statusIcon = schedule.getStatusIcon();
                bool showCompleteButton =
                    (schedule.status.toUpperCase() == 'UPCOMING' ||
                        schedule.status.toUpperCase() == 'OVERDUE');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  color: statusColor,
                  child: Padding(
                    // <-- Tambahkan Padding di sini
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding:
                              EdgeInsets.zero, // Hapus padding default ListTile
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.7),
                            child: Icon(statusIcon,
                                color: Theme.of(context).primaryColorDark,
                                size: 24),
                          ),
                          title: Text(schedule.itemName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('Berikutnya: ${schedule.displayDueDate}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[800])),
                              Text("Status: ${schedule.status}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[850])),
                              if (schedule.description != null &&
                                  schedule.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Text(
                                      "Catatan: ${schedule.description}",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[700])),
                                ),
                            ],
                          ),
                          trailing: showCompleteButton
                              ? ElevatedButton(
                                  onPressed: () => _showServiceCompletionDialog(
                                      context, schedule),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12)),
                                  child: const Text('Selesai'),
                                )
                              : (schedule.status.toUpperCase() == 'COMPLETED'
                                  ? Icon(Icons.check_circle_outline,
                                      color: Colors.green.shade700, size: 28)
                                  : null),
                        ),
                        // --- Tombol Rekomendasi Part (jika relevan) ---
                        if (isReplaceable) ...[
                          const Divider(height: 20, thickness: 0.5),
                          Center(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 18),
                              label: const Text(
                                  'Beli Spare Part di Official Store'),
                              onPressed:
                                  _launchPurchaseLink, // <-- LANGSUNG PANGGIL FUNGSI
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFee4d2d),
                                side:
                                    const BorderSide(color: Color(0xFFee4d2d)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ]
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
        onPressed: _loadSchedules,
        tooltip: 'Refresh Jadwal',
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
