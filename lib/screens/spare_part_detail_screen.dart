import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spare_part_model.dart';

class SparePartDetailScreen extends StatelessWidget { // Bisa jadi StatelessWidget
  final SparePart sparePart;

  const SparePartDetailScreen({
    Key? key,
    required this.sparePart, // Hanya butuh ini
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context, String? url) async {
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
        title: Text(sparePart.partName), // Judul lebih dinamis
      ),
      body: ListView(
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
            onPressed: () => _launchURL(context, sparePart.purchaseUrl),
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
      ),
    );
  }
}