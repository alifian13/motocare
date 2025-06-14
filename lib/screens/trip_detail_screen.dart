// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perjalanan pada:', style: Theme.of(context).textTheme.titleMedium),
            Text(
              trip.startTime != null ? DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(trip.startTime!) : 'Waktu tidak tersedia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Menggunakan trip.distanceKm
                    _buildDetailRow(context, Icons.route_outlined, 'Jarak Tempuh', '${trip.distanceKm.toStringAsFixed(2)} km'),
                    const Divider(height: 20),
                    // PERBAIKAN: Menggunakan trip.startAddress
                    _buildDetailRow(context, Icons.place_outlined, 'Dari', trip.startAddress ?? 'Tidak diketahui'),
                    const Divider(height: 20),
                    // PERBAIKAN: Menggunakan trip.endAddress
                    _buildDetailRow(context, Icons.flag_outlined, 'Ke', trip.endAddress ?? 'Tidak diketahui'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Detail peta akan ditampilkan di sini di masa mendatang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
