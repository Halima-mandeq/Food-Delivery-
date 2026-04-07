import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/core/config/app_config.dart';

class AuthService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String role = 'user',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
          'role': role,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(result['user'])};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(result['user'])};
      }

      return {'success': false, 'error': result['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }
}
