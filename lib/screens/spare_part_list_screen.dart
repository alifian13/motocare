import 'package:flutter/material.dart';
import '../models/spare_part_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import 'spare_part_detail_screen.dart';

class SparePartListScreen extends StatefulWidget {
  final Vehicle vehicle;

  const SparePartListScreen({super.key, required this.vehicle});
  static const routeName = '/spare-part-list';

  @override
  State<SparePartListScreen> createState() => _SparePartListScreenState();
}

class _SparePartListScreenState extends State<SparePartListScreen> {
  late Future<List<SparePart>> _sparePartsFuture;
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    // DEBUG: Cetak ID dan Kode saat halaman diinisialisasi
    debugPrint("Mengambil spare parts untuk Vehicle ID: ${widget.vehicle.vehicleId} dengan Kode: ${widget.vehicle.vehicleCode}");
    _sparePartsFuture = _vehicleService.getAllSpareParts(widget.vehicle.vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Katalog Part ${widget.vehicle.model}'),
        // Tampilkan kode motor di bawah judul untuk memastikan data benar
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Kode Motor: ${widget.vehicle.vehicleCode ?? "Tidak Ditemukan"}',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<SparePart>>(
        future: _sparePartsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                // Tampilkan pesan error dari backend
                child: Text('Gagal memuat: ${snapshot.error.toString()}', textAlign: TextAlign.center),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Katalog spare part untuk motor ini belum tersedia.", textAlign: TextAlign.center),
              ),
            );
          }

          final spareParts = snapshot.data!;
          return ListView.builder(
            itemCount: spareParts.length,
            itemBuilder: (context, index) {
              final part = spareParts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.settings_input_component_outlined),
                  title: Text(part.partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Kode: ${part.partCode}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SparePartDetailScreen(
                        sparePart: part,
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}