import 'package:flutter/material.dart';
import '../models/service_item.dart'; // Pindahkan atau buat model ini

List<ServiceItem> dummyHistoryItems = [
  ServiceItem(title: "Service CVT", date: "12/01/2025", odometer: "63147 km", plateNumber: "K 5036 AZF", icon: Icons.settings_applications_outlined),
  ServiceItem(title: "Pergantian Oli", date: "02/12/2024", odometer: "60100 km", plateNumber: "K 5036 AZF", icon: Icons.opacity_outlined),
];

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ganti dengan data dinamis dari database/SharedPreferences
    final List<ServiceItem> items = dummyHistoryItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Perawatan'),
      ),
      body: items.isEmpty
          ? const Center(child: Text("Belum ada history perawatan."))
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.5),
                      child: Icon(item.icon, color: Theme.of(context).primaryColorDark),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Plat: ${item.plateNumber}"),
                        Text("Tanggal: ${item.date}"),
                        Text("Odometer: ${item.odometer}"),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detail untuk ${item.title}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}