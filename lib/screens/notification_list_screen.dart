import 'package:flutter/material.dart';
import '../models/service_item.dart'; // Pindahkan atau buat model ini

List<ServiceItem> dummyNotificationItems = [
  ServiceItem(title: "Service Throttle Body", date: "Terlewat (target 52965 km)", odometer: "", plateNumber: "K 5036 AZF", icon: Icons.warning_amber_rounded, status: "TERLEWAT !!"),
  ServiceItem(title: "Pergantian Vanbelt", date: "Terlewat (target 52897 km)", odometer: "", plateNumber: "K 5036 AZF", icon: Icons.warning_amber_rounded, status: "TERLEWAT !!"),
  ServiceItem(title: "Bayar Pajak Tahunan", date: "Jatuh Tempo 01/08/2025", odometer: "", plateNumber: "K 5036 AZF", icon: Icons.notifications_active_outlined, status: "SEGERA"),
];

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ganti dengan data dinamis
    final List<ServiceItem> items = dummyNotificationItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Notifikasi'),
      ),
      body: items.isEmpty
          ? const Center(child: Text("Tidak ada notifikasi."))
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                bool isOverdue = item.status == "TERLEWAT !!";
                return Card(
                  color: isOverdue ? Colors.red[50] : (item.status == "SEGERA" ? Colors.orange[50] : null),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOverdue ? Colors.red[100] : (item.status == "SEGERA" ? Colors.orange[100] : Theme.of(context).primaryColorLight.withOpacity(0.5)),
                      child: Icon(
                        item.icon,
                        color: isOverdue ? Colors.red[700] : (item.status == "SEGERA" ? Colors.orange[700] : Theme.of(context).primaryColorDark),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red[700] : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.status != null && item.status!.isNotEmpty)
                          Text(
                            item.status!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red[700] : (item.status == "SEGERA" ? Colors.orange[700] : null),
                            ),
                          ),
                        Text("Plat: ${item.plateNumber}"),
                        Text("Keterangan: ${item.date}"),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detail notifikasi untuk ${item.title}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}