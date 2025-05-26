// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart'; // Pastikan path ini benar

class ApiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      // PERBAIKAN: Ubah 'UTF-o-8' menjadi 'UTF-8'
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    print('[ApiService] GET: $url'); // Logging
    print('[ApiService] Headers: $headers'); // Logging
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = jsonEncode(body);
    print('[ApiService] POST: $url'); // Logging
    print('[ApiService] Headers: $headers'); // Logging
    print('[ApiService] Body: $encodedBody'); // Logging
    return http.post(url, headers: headers, body: encodedBody);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = jsonEncode(body);
    print('[ApiService] PUT: $url'); // Logging
    print('[ApiService] Headers: $headers'); // Logging
    print('[ApiService] Body: $encodedBody'); // Logging
    return http.put(url, headers: headers, body: encodedBody);
  }

  // Tambahkan method delete jika perlu
  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    final encodedBody = body != null ? jsonEncode(body) : null;
    print('[ApiService] DELETE: $url'); // Logging
    print('[ApiService] Headers: $headers'); // Logging
    if (encodedBody != null) print('[ApiService] Body: $encodedBody'); // Logging
    return http.delete(url, headers: headers, body: encodedBody);
  }
}
