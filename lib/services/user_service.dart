// services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Replace with your actual API base URL.
  // For Android emulator, if API is on localhost: http://10.0.2.2:PORT
  // For iOS simulator, if API is on localhost: http://localhost:PORT
  // If testing on a physical device, use your computer's network IP address.
  final String _baseUrl = "http://127.0.0.1:3000/api"; // EXAMPLE FOR ANDROID EMULATOR

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String address,
    required String plateNumber, // Changed from optional
    required String brand,       // Changed from optional
    required String motorModel,    // Changed from optional
    int? currentOdometer,
    DateTime? lastServiceDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
          'address': address,
          'plate_number': plateNumber,
          'brand': brand,
          'model': motorModel,
          'current_odometer': currentOdometer,
          'last_service_date': lastServiceDate?.toIso8601String().split('T')[0], // Send only YYYY-MM-DD
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print("Register User Exception: $e");
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  Future<Map<String, dynamic>> loginUser({
  required String email,
  required String password,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'), // Pastikan _baseUrl sudah benar
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) { // OK
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
      await prefs.setInt('userId', responseData['user']['user_id']); // Simpan user_id
      await prefs.setString('userName', responseData['user']['name']);
      await prefs.setString('userEmail', responseData['user']['email']);
      // Anda bisa menyimpan detail pengguna lain jika perlu
      return {'success': true, 'data': responseData};
    } else {
      return {'success': false, 'message': responseData['message'] ?? 'Login gagal'};
    }
  } catch (e) {
    print("Error Login User: $e");
    return {'success': false, 'message': 'Tidak dapat terhubung ke server: $e'};
  }
}

   Future<Map<String, dynamic>> getMyNotifications() async {
    print("UserService: getMyNotifications called"); // DEBUG
    try {
      String? token = await getToken();
      if (token == null) {
        print("UserService: No token found for getMyNotifications"); // DEBUG
        return {'success': false, 'message': 'User not authenticated.'};
      }

      print("UserService: Fetching notifications with token..."); // DEBUG
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/my-notifications'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15)); // Tambahkan timeout untuk mencegah hang selamanya

      print('Get Notifications Status Code: ${response.statusCode}'); // DEBUG
      print('Get Notifications Body: ${response.body}'); // DEBUG

      // Periksa jika body kosong sebelum decode, meskipun API yang baik akan tetap mengembalikan JSON ({}, [])
      if (response.body.isEmpty) {
        print("UserService: Empty response body from server."); //DEBUG
        if (response.statusCode == 200) {
             // Jika server mengembalikan 200 dengan body kosong, anggap sebagai data kosong
             return {'success': true, 'data': []};
        }
        return {'success': false, 'message': 'Respons kosong dari server.'};
      }

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        print("UserService: getMyNotifications success"); // DEBUG
        return {'success': true, 'data': responseData};
      } else {
        print("UserService: getMyNotifications failed with status ${response.statusCode}"); // DEBUG
        return {'success': false, 'message': responseData['message'] ?? 'Failed to fetch notifications from server'};
      }
    } catch (e, stackTrace) { // Tangkap stackTrace juga
      print("GetMyNotifications Exception: $e"); // DEBUG
      print("Stack Trace: $stackTrace"); // DEBUG
      return {'success': false, 'message': 'Tidak dapat terhubung ke server atau terjadi kesalahan: $e'};
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    // Clear other stored user data
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      String? token = await getToken();
      if (token == null) return {'success': false, 'message': 'Belum login'};

      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Gagal mengambil profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserName(String newName) async {
    try {
      String? token = await getToken();
      if (token == null) return {'success': false, 'message': 'Belum login'};

      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Update nama di SharedPreferences juga
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', responseData['user']['name']);
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Gagal update nama'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfilePicture(File imageFile) async {
    try {
      String? token = await getToken();
      if (token == null) return {'success': false, 'message': 'Belum login'};

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/profile/picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture', // Nama field yang sama dengan di backend (upload.single('profilePicture'))
          imageFile.path,
          contentType: MediaType('image', imageFile.path.split('.').last), // Dapatkan ekstensi
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
         // Simpan URL foto baru ke SharedPreferences jika perlu untuk update cepat di UI lain
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // await prefs.setString('userPhotoUrl', responseData['filePath']);
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Gagal unggah foto'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // This replaces your old getUserData from SharedPreferences for data that now comes from the DB
  // You'll likely call specific endpoints for specific data (e.g., vehicles, profile)
  // For a simple profile data, you might have a /api/users/profile endpoint
  // Or just use the data returned from login and stored in SharedPreferences for display.
}