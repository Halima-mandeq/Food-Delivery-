import 'dart:convert';

import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

class AdminOrderRecord {
  const AdminOrderRecord({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.deliveryAddress,
  });

  final int id;
  final int userId;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? deliveryAddress;

  factory AdminOrderRecord.fromJson(Map<String, dynamic> json) {
    return AdminOrderRecord(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: (json['status']?.toString() ?? '').trim(),
      createdAt: _parseDateTime(json['created_at']?.toString()),
      customerName: json['customer_name']?.toString().trim().isNotEmpty == true
          ? json['customer_name'].toString().trim()
          : 'Unknown Customer',
      customerEmail: json['customer_email']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
    );
  }

  static DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }
}

class AdminOrderService {
  static String get baseUrl => AuthService.baseUrl;

  Future<List<AdminOrderRecord>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/get_admin_orders.php'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load admin orders (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid admin orders response');
    }

    return decoded
        .map(
          (item) => AdminOrderRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
