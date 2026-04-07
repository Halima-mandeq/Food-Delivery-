import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:food_delivery_frontend/features/home/data/models/home_promotion_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/menu_item_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';

class ProductService {
  static final String baseUrl = AuthService.baseUrl;

  Future<List<ProductModel>> getProducts({
    String? category,
    String? search,
    bool includeUnavailable = false,
    bool featuredOnly = false,
  }) async {
    try {
      List<String> queryParams = [];
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams.add('category=${Uri.encodeComponent(category)}');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }
      if (includeUnavailable) {
        queryParams.add('include_unavailable=1');
      }
      if (featuredOnly) {
        queryParams.add('featured_only=1');
      }

      String url = '$baseUrl/get_products.php';
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_categories.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => item.toString().trim())
            .where((category) => category.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<MenuItemModel>> getMenuItems(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_menu_items.php?restaurant_id=$restaurantId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => MenuItemModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      debugPrint('Error fetching menu items: $e');
      return [];
    }
  }

  Future<List<HomePromotionModel>> getHomePromotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_home_promotions.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HomePromotionModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load home promotions');
      }
    } catch (e) {
      debugPrint('Error fetching home promotions: $e');
      return [];
    }
  }
}
