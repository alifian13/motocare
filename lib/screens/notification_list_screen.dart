// lib/screens/notification_list_screen.dart
import 'package:flutter/material.dart';
import '../models/notification_item.dart'; // Model baru
import '../services/user_service.dart'; // Atau NotificationService jika Anda buat terpisah

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  // Asumsi metode getMyNotifications ada di UserService
  final UserService _userService = UserService();
  List<NotificationItem> _notificationItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _userService.getMyNotifications();

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      if (result['data'] is List) {
        List<dynamic> notificationListJson = result['data'] as List<dynamic>;
        setState(() {
          _notificationItems = notificationListJson
              .map((json) {
                if (json is Map<String, dynamic>) {
                  return NotificationItem.fromJson(json);
                }
                return null;
              })
              .whereType<NotificationItem>()
              .toList();
          _isLoading = false;
        });
      } else {
         setState(() {
          _errorMessage = 'Format data notifikasi tidak sesuai dari server.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat notifikasi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Notifikasi'),
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
                        ElevatedButton(onPressed: _fetchNotifications, child: const Text('Coba Lagi'))
                      ],
                    ),
                  ))
              : _notificationItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                           SizedBox(height: 16),
                           Text("Tidak ada notifikasi saat ini.", textAlign: TextAlign.center),
                        ],
                      ))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: _notificationItems.length,
                        itemBuilder: (context, index) {
                          final item = _notificationItems[index];
                          return Card(
                            elevation: 1.5,
                            color: item.getNotificationColor(context),
                            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(item.isRead ? 0.05 : 0.1),
                                child: Icon(item.getNotificationIcon(), color: item.isRead ? Colors.grey : Theme.of(context).primaryColorDark),
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
                                  Text(item.formattedCreatedAt, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                              // trailing: item.isRead ? null : Icon(Icons.circle, color: Colors.blueAccent, size: 12), // Indikator belum dibaca
                              onTap: () {
                                // TODO: Aksi saat notifikasi di-tap (misal, tandai sudah dibaca, navigasi ke detail terkait)
                                // setState(() { item.isRead = true; }); // Ini hanya mengubah state lokal, perlu update ke API
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Notifikasi "${item.title}" di-tap.')),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}