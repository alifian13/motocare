// lib/screens/contact_us_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka link email dan telepon

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});
  static const routeName = '/contact-us';

  // Fungsi untuk meluncurkan URL (email atau telepon)
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Bisa tambahkan fallback atau pesan error jika gagal launch
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    const String emailDeveloper = 'ilhamm6812@gmail.com';
    const String phoneDeveloper = '+6285325814769'; // Format internasional untuk WhatsApp/Telepon
    const String whatsappNumber = '6285325814769'; // Nomor tanpa + untuk link WhatsApp

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubungi Kami'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Icon(
                Icons.support_agent, // Atau Icons.contact_mail
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Informasi Pengembang Aplikasi MotoCare',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Jika Anda memiliki pertanyaan, masukan, atau membutuhkan bantuan terkait aplikasi MotoCare, jangan ragu untuk menghubungi pengembang melalui kontak di bawah ini:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
                      title: const Text('Email Pengembang', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(emailDeveloper),
                      onTap: () => _launchUrl('mailto:$emailDeveloper?subject=Pertanyaan%20MotoCare'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
                      title: const Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(phoneDeveloper),
                      onTap: () => _launchUrl('tel:$phoneDeveloper'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.message_outlined, color: Theme.of(context).primaryColor), // Bisa ganti ikon WhatsApp jika ada
                      title: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(phoneDeveloper),
                      onTap: () => _launchUrl('https://wa.me/$whatsappNumber?text=Halo,%20saya%20ingin%20bertanya%20tentang%20aplikasi%20MotoCare.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Terima kasih telah menggunakan MotoCare!',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
