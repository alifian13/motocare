// lib/screens/notification_list_screen.dart
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart'; // <-- GUNAKAN NotificationService

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});
  static const routeName = '/notifications';

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService(); // <-- Gunakan NotificationService
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _notificationsFuture = _notificationService.getMyNotifications(); // Panggil dari _notificationService
    });
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;

    final result = await _notificationService.markNotificationAsRead(item.notificationId);
    if (mounted) {
      if (result['success']) {
        _loadNotifications(); // Muat ulang daftar notifikasi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifikasi "${item.title}" ditandai sudah dibaca.'), duration: const Duration(seconds: 2)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menandai notifikasi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Notifikasi'),
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center( /* ... UI Error ... */ );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center( /* ... UI Kosong ... */ );
          }
          final notificationItems = snapshot.data!;
          return RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: notificationItems.length,
                itemBuilder: (context, index) {
                  final item = notificationItems[index];
                  return Card(
                    elevation: 1.5,
                    color: item.isRead ? Colors.white : Colors.blue.shade50,
                    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isRead ? Colors.grey.shade300 : Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          item.getNotificationIcon(),
                          color: item.isRead ? Colors.grey.shade600 : Theme.of(context).primaryColorDark
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                          color: item.isRead ? Colors.grey[700] : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.message, style: TextStyle(fontSize: 13, color: item.isRead ? Colors.grey[600] : Colors.black54)),
                          const SizedBox(height: 4),
                          Text(item.formattedCreatedAt ?? "Baru saja", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                      trailing: item.isRead ? null : Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                      onTap: () {
                        _markAsRead(item);
                      },
                    ),
                  );
                },
              ),
            );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNotifications,
        tooltip: 'Refresh Notifikasi',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
