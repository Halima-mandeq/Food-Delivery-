import 'dart:convert';

import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:http/http.dart' as http;

class AdminRestaurantRecord {
  const AdminRestaurantRecord({
    required this.restaurant,
    required this.totalOrders,
  });

  final ProductModel restaurant;
  final int totalOrders;

  factory AdminRestaurantRecord.fromJson(Map<String, dynamic> json) {
    return AdminRestaurantRecord(
      restaurant: ProductModel.fromJson(json),
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
    );
  }
}

class AdminRestaurantService {
  static String get baseUrl => AuthService.baseUrl;

  Future<List<AdminRestaurantRecord>> getRestaurants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_admin_restaurants.php'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load restaurants (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid restaurant response');
    }

    return decoded
        .map(
          (item) => AdminRestaurantRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
