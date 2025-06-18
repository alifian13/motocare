import 'package:intl/intl.dart';
import 'vehicle_model.dart'; 

class UserData {
  final String? name;
  final String? email;
  final String? address;
  final String? userPhotoUrl;
  final Vehicle? vehicle;

  final String? plateNumber;
  final String? brand;
  final String? vehicleModel;
  final int? currentOdometer;
  final String? lastServiceDate;
  final String? vehiclePhotoUrl; 
  final String? vehicleLogoUrl;

  UserData({
    this.name,
    this.email,
    this.address,
    this.userPhotoUrl,
    this.vehicle,
    this.plateNumber,
    this.brand,
    this.vehicleModel,
    this.currentOdometer,
    this.lastServiceDate,
    this.vehiclePhotoUrl,
    this.vehicleLogoUrl,
  });

  String? get formattedLastServiceDate {
    if (lastServiceDate == null || lastServiceDate!.isEmpty) return "N/A";
    try {
      final date = DateFormat("yyyy-MM-dd").parse(lastServiceDate!);
      return DateFormat("dd MMMM yyyy", "id_ID").format(date);
    } catch (e) {
      return lastServiceDate;
    }
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      userPhotoUrl: json['photo_url'] as String?,
    );
  }

  static UserData combine(Map<String, dynamic>? userDataJson, Vehicle? primaryVehicle) {
    return UserData(
      name: userDataJson?['name'] as String?,
      email: userDataJson?['email'] as String?,
      userPhotoUrl: userDataJson?['userPhotoUrl'] as String?,
      address: userDataJson?['address'] as String?,
      vehicle: primaryVehicle,
      plateNumber: primaryVehicle?.plateNumber,
      brand: primaryVehicle?.brand,
      vehicleModel: primaryVehicle?.model,
      currentOdometer: primaryVehicle?.currentOdometer,
      lastServiceDate: primaryVehicle?.lastServiceDate,
      vehiclePhotoUrl: primaryVehicle?.photoUrl,
      vehicleLogoUrl: primaryVehicle?.logoUrl,
    );
  }
}