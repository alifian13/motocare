import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motocare/models/user_data_model.dart';
import 'package:motocare/services/api_service.dart';
import 'package:motocare/utils/constants.dart';

class UserService {
  final ApiService _apiService = ApiService();

  static const String prefToken = 'token';
  static const String prefUserId = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserEmail = 'user_email';
  static const String prefUserPhotoUrl = 'user_photo_url';
  static const String prefCurrentVehicleId = 'current_vehicle_id';


  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    String? address,
    required String plateNumber,
    required String brand,
    required String model,
    required int currentOdometer,
    String? lastServiceDate,
    List<Map<String, dynamic>>? initialServices,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        'plate_number': plateNumber,
        'brand': brand,
        'model': model,
        'current_odometer': currentOdometer,
        if (lastServiceDate != null) 'last_service_date': lastServiceDate,
        if (initialServices != null && initialServices.isNotEmpty) 'initialServices': initialServices,
      };

      final response = await _apiService.post('/users/register', requestBody, requiresAuth: false);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey('token') && responseData.containsKey('user')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(prefToken, responseData['token']);
          await prefs.setString(prefUserId, responseData['user']['user_id'].toString());
          await prefs.setString(prefUserName, responseData['user']['name']);
          await prefs.setString(prefUserEmail, responseData['user']['email']);
          if (responseData['user']['photo_url'] != null) {
            await prefs.setString(prefUserPhotoUrl, responseData['user']['photo_url']);
          }
          if (responseData.containsKey('vehicle') && responseData['vehicle']['vehicle_id'] != null) {
            await prefs.setString(prefCurrentVehicleId, responseData['vehicle']['vehicle_id'].toString());
          }
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      print('[UserService] Error di registerUser: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await _apiService.post('/users/login', {
        'email': email,
        'password': password,
      }, requiresAuth: false);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData.containsKey('token') && responseData.containsKey('user')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(prefToken, responseData['token']);
        await prefs.setString(prefUserId, responseData['user']['user_id'].toString());
        await prefs.setString(prefUserName, responseData['user']['name']);
        await prefs.setString(prefUserEmail, responseData['user']['email']);
        if (responseData['user']['photo_url'] != null) {
          await prefs.setString(prefUserPhotoUrl, responseData['user']['photo_url']);
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      print('[UserService] Error di loginUser: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  Future<UserData?> getUserProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      if (response.statusCode == 200) {
        final userDataJson = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if(userDataJson['name'] != null) await prefs.setString(prefUserName, userDataJson['name']);
        if(userDataJson['email'] != null) await prefs.setString(prefUserEmail, userDataJson['email']);
        if(userDataJson['photo_url'] != null) {
          await prefs.setString(prefUserPhotoUrl, userDataJson['photo_url']);
        } else {
          await prefs.remove(prefUserPhotoUrl);
        }

        return UserData.fromJson(userDataJson);
      } else {
        print('[UserService] Gagal mendapatkan profil: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('[UserService] Error di getUserProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateUserProfileData(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put('/users/profile/update', profileData);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if(responseBody['user']?['name'] != null) await prefs.setString(prefUserName, responseBody['user']['name']);
        if(responseBody['user']?['email'] != null) await prefs.setString(prefUserEmail, responseBody['user']['email']);
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Update profil gagal'};
      }
    } catch (e) {
      print('[UserService] Error di updateUserProfileData: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateUserName(String newName) async {
    return updateUserProfileData({'name': newName});
  }

  Future<Map<String, dynamic>> updateUserProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(prefToken);
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/users/profile/upload-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profilePicture', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['filePath'] != null) {
            await prefs.setString(prefUserPhotoUrl, responseData['filePath']);
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Upload foto gagal'};
      }
    } catch (e) {
      print('[UserService] Error di updateUserProfilePicture: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefToken);
    await prefs.remove(prefUserId);
    await prefs.remove(prefUserName);
    await prefs.remove(prefUserEmail);
    await prefs.remove(prefUserPhotoUrl);
    await prefs.remove(prefCurrentVehicleId);
    print("[UserService] User logged out, SharedPreferences cleared.");
  }
}
