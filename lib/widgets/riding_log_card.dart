// lib/widgets/riding_log_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../utils/date_formatter.dart';

class RidingLogCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const RidingLogCard({super.key, required this.trip, required this.onTap});

  // Helper widget untuk baris info (lokasi, tanggal, jarak)
  Widget _buildInfoRow(IconData icon, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format data perjalanan untuk ditampilkan
    // PERBAIKAN: Menggunakan trip.startAddress dan trip.endAddress
    final startLocation = trip.startAddress ?? 'Lokasi Awal Tidak Diketahui';
    final endLocation = trip.endAddress ?? 'Lokasi Akhir Tidak Diketahui';
    final formattedDate = DateFormatter.toWibString(trip.endTime, format: 'dd/MM/yyyy');
    final formattedTime = (trip.startTime != null && trip.endTime != null)
        ? '${DateFormatter.toWibString(trip.startTime, format: 'HH:mm')} - ${DateFormatter.toWibString(trip.endTime, format: 'HH:mm')}'
        : 'N/A';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Card(
        clipBehavior: Clip.antiAlias, // Agar gambar tidak keluar dari border radius
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kolom untuk gambar peta
              Expanded(
                flex: 2,
                child: Image.asset(
                  'assets/images/map_placeholder.png', // Pastikan Anda punya aset ini
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gambar map placeholder tidak ada
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.map, color: Colors.grey, size: 50),
                    );
                  },
                ),
              ),
              // Kolom untuk detail perjalanan
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_circle, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Riding Log',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(Icons.location_on_outlined, '$startLocation -> $endLocation', context),
                      _buildInfoRow(Icons.calendar_today_outlined, '$formattedDate, $formattedTime', context),
                      // PERBAIKAN: Menggunakan trip.distanceKm
                      _buildInfoRow(Icons.route_outlined, '${trip.distanceKm.toStringAsFixed(1)} km', context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
