import 'package:flutter/material.dart';
import '../models/service_item.dart'; // Pindahkan atau buat model ini

List<ServiceItem> dummyScheduleItems = [
  ServiceItem(title: "Service CVT", date: "Prediksi 12/07/2025", odometer: "Target 70000 km", plateNumber: "K 5036 AZF", icon: Icons.event_available_outlined),
  ServiceItem(title: "Ganti Oli Mesin", date: "Prediksi 02/06/2025", odometer: "Target 68000 km", plateNumber: "K 5036 AZF", icon: Icons.event_available_outlined),
];

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ganti dengan data dinamis
    final List<ServiceItem> items = dummyScheduleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Perawatan'),
      ),
      body: items.isEmpty
          ? const Center(child: Text("Belum ada jadwal perawatan."))
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(item.icon, color: Colors.green[700]),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Plat: ${item.plateNumber}"),
                        Text("Jadwal: ${item.date}"),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detail jadwal untuk ${item.title}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}