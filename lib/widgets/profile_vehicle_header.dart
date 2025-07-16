import 'package:flutter/material.dart';

class ProfileVehicleHeader extends StatelessWidget {
  final String? userName;
  final String? userPhotoUrl;
  final String? vehicleLogoUrl;
  final String baseImageUrl;

  const ProfileVehicleHeader({
    super.key,
    required this.userName,
    required this.userPhotoUrl,
    required this.vehicleLogoUrl,
    required this.baseImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object> userAvatarImage;
    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
      userAvatarImage = NetworkImage(userPhotoUrl!.startsWith('http')
          ? userPhotoUrl!
          : baseImageUrl + userPhotoUrl!);
    } else {
      userAvatarImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: userAvatarImage,
                  onBackgroundImageError: (exception, stackTrace) {
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
                return const Icon(Icons.motorcycle, size: 40, color: Colors.grey);
              },
            )
          else
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
