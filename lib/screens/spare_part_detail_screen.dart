import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spare_part_model.dart';
import '../services/api_service.dart';

class SparePartDetailScreen extends StatefulWidget {
  final int vehicleId;
  final String serviceName;

  const SparePartDetailScreen({
    Key? key,
    required this.vehicleId,
    required this.serviceName,
  }) : super(key: key);

  @override
  _SparePartDetailScreenState createState() => _SparePartDetailScreenState();
}

class _SparePartDetailScreenState extends State<SparePartDetailScreen> {
  late Future<SparePart> _sparePartFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // --- PERBAIKAN DI SINI ---
    // Menggunakan nama fungsi yang benar: getSparePart
    _sparePartFuture = _apiService.getSparePart(widget.vehicleId, widget.serviceName);
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pembelian tidak tersedia.')),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Spare Part'),
      ),
      body: FutureBuilder<SparePart>(
        future: _sparePartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error: ${snapshot.error.toString()}', textAlign: TextAlign.center),
              )
            );
          } else if (snapshot.hasData) {
            final sparePart = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sparePart.partName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Untuk Servis: ${sparePart.serviceName}',
                           style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 32),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.qr_code_2_rounded, color: Theme.of(context).primaryColor),
                          title: const Text('Kode Part Original'),
                          subtitle: SelectableText(
                            sparePart.partCode,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (sparePart.description != null && sparePart.description!.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                            title: const Text('Deskripsi'),
                            subtitle: Text(sparePart.description!),
                          ),
                      ],
                    ),
                  )
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Beli di Official Store'),
                  onPressed: () => _launchURL(sparePart.purchaseUrl),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFee4d2d),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Data spare part tidak ditemukan.'));
          }
        },
      ),
    );
  }
}