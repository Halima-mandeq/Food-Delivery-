import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/customer_order_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/presentation/models/cart_models.dart';

class OrderService {
  static String get baseUrl => AuthService.baseUrl;

  Future<CustomerOrderModel> placeOrder({
    required UserModel user,
    required ProductModel restaurant,
    required List<CartLineItem> cartItems,
    required double deliveryFee,
    required double taxAmount,
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/place_order.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': user.id,
        'restaurant': {
          'id': restaurant.id,
          'name': restaurant.name,
          'image_url': restaurant.imageUrl,
          'delivery_time': restaurant.deliveryTime,
        },
        'delivery_address': deliveryAddress,
        'delivery_fee': deliveryFee,
        'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        'estimated_delivery_time': restaurant.deliveryTime,
        'items': cartItems
            .map(
              (cartItem) => {
                'menu_item_id': cartItem.item.id,
                'name': cartItem.item.name,
                'image_url': cartItem.item.imageUrl,
                'selected_options': cartItem.selectedOptions
                    .map(
                      (option) => {
                        'title': option.title,
                        'price_delta': option.priceDelta,
                      },
                    )
                    .toList(),
                'notes': cartItem.notes,
                'quantity': cartItem.quantity,
                'unit_price': cartItem.unitPrice,
              },
            )
            .toList(),
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['error']?.toString() ?? 'Failed to place order.'
            : 'Failed to place order.',
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['order'] is! Map) {
      throw Exception('Invalid order response from the server.');
    }

    return CustomerOrderModel.fromJson(
      Map<String, dynamic>.from(decoded['order'] as Map),
    );
  }

  Future<List<CustomerOrderModel>> getOrdersForUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_user_orders.php?user_id=$userId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load your orders.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid orders response from the server.');
      }

      return decoded
          .map(
            (item) =>
                CustomerOrderModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (error) {
      debugPrint('Error fetching customer orders: $error');
      rethrow;
    }
  }
}
