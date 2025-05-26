// lib/services/user_service.dart
import 'dart:convert';
import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motocare/models/user_data_model.dart';
import 'package:motocare/services/api_service.dart';
import 'package:motocare/utils/constants.dart'; // <-- TAMBAHKAN IMPOR INI

class UserService {
  final ApiService _apiService = ApiService();

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
        if (responseData.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
           // Simpan data user dasar jika ada
          if (responseData.containsKey('user')) {
            await prefs.setString('user_id', responseData['user']['user_id'].toString());
            await prefs.setString('user_name', responseData['user']['name']);
            await prefs.setString('user_email', responseData['user']['email']);
            // Anda bisa menyimpan photo_url di sini jika dikembalikan saat registrasi
            if (responseData['user']['photo_url'] != null) {
                await prefs.setString('user_photo_url', responseData['user']['photo_url']);
            }
          }
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      print('Error di registerUser: $e');
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

      if (response.statusCode == 200 && responseData.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        if (responseData.containsKey('user')) {
             await prefs.setString('user_id', responseData['user']['user_id'].toString());
             await prefs.setString('user_name', responseData['user']['name']);
             await prefs.setString('user_email', responseData['user']['email']);
             if (responseData['user']['photo_url'] != null) { // Simpan photo_url saat login
                await prefs.setString('user_photo_url', responseData['user']['photo_url']);
             }
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      print('Error di loginUser: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // Mengembalikan UserData? agar ProfileScreen bisa menggunakannya langsung
  Future<UserData?> getUserProfile() async {
    try {
      final response = await _apiService.get('/users/profile');
      if (response.statusCode == 200) {
        // Backend Anda mengirim langsung objek user, bukan dibungkus 'data'
        return UserData.fromJson(jsonDecode(response.body));
      } else {
        print('Gagal mendapatkan profil: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error di getUserProfile: $e');
      return null;
    }
  }

  // Metode generik untuk update profil (termasuk alamat dll, jika backend mendukung)
  Future<Map<String, dynamic>> updateUserProfileData(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put('/users/profile/update', profileData);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Perbarui data user di SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if(responseBody['user']?['name'] != null) await prefs.setString('user_name', responseBody['user']['name']);
        // Tambahkan update untuk field lain jika perlu
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Update profil gagal'};
      }
    } catch (e) {
      print('Error di updateUserProfileData: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  // Metode spesifik untuk update nama pengguna
  Future<Map<String, dynamic>> updateUserName(String newName) async {
    return updateUserProfileData({'name': newName}); // Memanfaatkan metode generik
  }


  // Mengganti nama metode dari uploadProfilePicture ke updateUserProfilePicture
  // agar sesuai dengan panggilan di ProfileScreen
  Future<Map<String, dynamic>> updateUserProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      var request = http.MultipartRequest(
        'POST', // Backend Anda menggunakan POST untuk upload gambar profil
        Uri.parse('${ApiConstants.baseUrl}/users/profile/upload-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profilePicture', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
         // Perbarui photo_url di SharedPreferences
        if (responseData['filePath'] != null) {
            await prefs.setString('user_photo_url', responseData['filePath']);
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Upload foto gagal'};
      }
    } catch (e) {
      print('Error di updateUserProfilePicture: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: ${e.toString()}'};
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo_url'); // Hapus juga photo_url
    await prefs.remove('current_vehicle_id'); // Hapus kendaraan aktif
  }
}
