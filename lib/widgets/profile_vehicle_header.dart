import 'package:flutter/material.dart';

class ProfileVehicleHeader extends StatelessWidget {
  final String? userName;
  final String? userPhotoUrl;
  final String? vehicleLogoUrl;
  final String baseImageUrl; // URL dasar untuk gambar jika path-nya relatif

  const ProfileVehicleHeader({
    super.key,
    required this.userName,
    required this.userPhotoUrl,
    required this.vehicleLogoUrl,
    required this.baseImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Menentukan gambar avatar pengguna
    ImageProvider<Object> userAvatarImage;
    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
      userAvatarImage = NetworkImage(userPhotoUrl!.startsWith('http')
          ? userPhotoUrl!
          : baseImageUrl + userPhotoUrl!);
    } else {
      // Fallback jika tidak ada foto profil
      userAvatarImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Profil Pengguna
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: userAvatarImage,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle error jika gambar gagal dimuat
                    print("Error loading profile image: $exception");
                  },
                  child: (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                      ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      Text(
                        userName ?? 'Pengguna',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bagian Logo Kendaraan
          if (vehicleLogoUrl != null && vehicleLogoUrl!.isNotEmpty)
            Image.network(
              vehicleLogoUrl!.startsWith('http') ? vehicleLogoUrl! : baseImageUrl + vehicleLogoUrl!,
              height: 100,
              width: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback jika logo kendaraan gagal dimuat
                return const Icon(Icons.motorcycle, size: 40, color: Colors.grey);
              },
            )
          else
            // Tampilkan placeholder jika tidak ada logo
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.motorcycle, size: 30, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
