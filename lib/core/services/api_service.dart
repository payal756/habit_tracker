import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's IP address
  static const String computerIp = '192.168.1.30'; // CHANGE THIS!

  static String get baseUrl {
    if (Platform.isAndroid) {
      // For physical device, use computer's IP
      return 'http://$computerIp:3000/api';
    }
    // For emulator
    else if (Platform.isAndroid &&
        Platform.environment.containsKey('ANDROID_EMULATOR')) {
      return 'http://10.0.2.2:3000/api';
    }
    // For iOS simulator
    else {
      return 'http://localhost:3000/api';
    }
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Save token after login/register
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // Clear all stored data on logout
  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .post(url, headers: await _getHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(url, headers: await _getHeaders(), body: json.encode(data))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
          // If the response is a list, wrap it in a 'data' field
          return {'data': decoded};
        } else {
          return {'data': decoded};
        }
      } catch (e) {
        throw Exception('Invalid response format');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
