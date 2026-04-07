import 'dart:convert';

import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

enum AdminUserStatus { active, suspended }

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.totalOrders,
    this.phoneNumber,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;
  final DateTime? createdAt;
  final int totalOrders;

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    return AdminUserRecord(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString().trim().isNotEmpty == true
          ? json['full_name'].toString().trim()
          : 'Unknown User',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      role: (json['role']?.toString() ?? 'user').toLowerCase(),
      createdAt: _parseDateTime(json['created_at']?.toString()),
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
    );
  }

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }
}

class AdminUserService {
  static String get baseUrl => AuthService.baseUrl;

  Future<List<AdminUserRecord>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/get_admin_users.php'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load admin users (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid admin users response');
    }

    return decoded
        .map(
          (item) => AdminUserRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String role = 'user',
  }) async {
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

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid create user response');
    }

    if (response.statusCode >= 400) {
      throw Exception(decoded['error']?.toString() ?? 'Failed to create user');
    }

    return decoded;
  }
}
