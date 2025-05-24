import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Location location = Location();

  Future<LatLng?> getCurrentLocation() async {
    try {
      // Meminta izin akses lokasi
      bool _serviceEnabled;
      PermissionStatus _permissionGranted;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        // Jika layanan lokasi tidak aktif, aktifkan
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return null;  // Tidak bisa mengakses lokasi jika layanan mati
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        // Jika izin lokasi tidak diberikan, minta izin
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return null;  // Tidak bisa mengakses lokasi tanpa izin
        }
      }

      // Mengambil data lokasi jika izin dan layanan diaktifkan
      LocationData currentLocation = await location.getLocation();
      return LatLng(currentLocation.latitude!, currentLocation.longitude!);
    } catch (e) {
      print("Error getting location: $e");
      return null;  // Kembalikan null jika terjadi error
    }
  }
}
