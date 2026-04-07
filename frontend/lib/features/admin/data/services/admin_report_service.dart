import 'dart:convert';

import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

class AdminReportSummary {
  const AdminReportSummary({
    required this.totalRevenue,
    required this.averageOrder,
    required this.completedOrders,
    required this.totalOrders,
    required this.customerCount,
    required this.newCustomers,
    required this.revenueGrowthPercent,
    required this.customerGrowthPercent,
  });

  const AdminReportSummary.empty()
      : totalRevenue = 0,
        averageOrder = 0,
        completedOrders = 0,
        totalOrders = 0,
        customerCount = 0,
        newCustomers = 0,
        revenueGrowthPercent = 0,
        customerGrowthPercent = 0;

  final double totalRevenue;
  final double averageOrder;
  final int completedOrders;
  final int totalOrders;
  final int customerCount;
  final int newCustomers;
  final double revenueGrowthPercent;
  final double customerGrowthPercent;

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    return AdminReportSummary(
      totalRevenue: _asDouble(json['total_revenue']),
      averageOrder: _asDouble(json['average_order']),
      completedOrders: _asInt(json['completed_orders']),
      totalOrders: _asInt(json['total_orders']),
      customerCount: _asInt(json['customer_count']),
      newCustomers: _asInt(json['new_customers']),
      revenueGrowthPercent: _asDouble(json['revenue_growth_percent']),
      customerGrowthPercent: _asDouble(json['customer_growth_percent']),
    );
  }
}

class AdminReportRevenuePoint {
  const AdminReportRevenuePoint({
    required this.label,
    required this.date,
    required this.amount,
  });

  final String label;
  final String date;
  final double amount;

  factory AdminReportRevenuePoint.fromJson(Map<String, dynamic> json) {
    return AdminReportRevenuePoint(
      label: json['label']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: _asDouble(json['amount']),
    );
  }
}

class AdminReportCategory {
  const AdminReportCategory({
    required this.label,
    required this.count,
    required this.percentage,
  });

  final String label;
  final int count;
  final int percentage;

  factory AdminReportCategory.fromJson(Map<String, dynamic> json) {
    return AdminReportCategory(
      label: json['label']?.toString() ?? '',
      count: _asInt(json['count']),
      percentage: _asInt(json['percentage']),
    );
  }
}

class AdminReportVendor {
  const AdminReportVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.totalOrders,
    required this.amount,
    required this.metric,
    required this.status,
  });

  final int id;
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final int totalOrders;
  final double amount;
  final String metric;
  final String status;

  factory AdminReportVendor.fromJson(Map<String, dynamic> json) {
    return AdminReportVendor(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      rating: _asDouble(json['rating']),
      totalOrders: _asInt(json['total_orders']),
      amount: _asDouble(json['amount']),
      metric: json['metric']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class AdminReportsData {
  const AdminReportsData({
    required this.summary,
    required this.weeklyRevenue,
    required this.categories,
    required this.vendors,
  });

  const AdminReportsData.empty()
      : summary = const AdminReportSummary.empty(),
        weeklyRevenue = const <AdminReportRevenuePoint>[],
        categories = const <AdminReportCategory>[],
        vendors = const <AdminReportVendor>[];

  final AdminReportSummary summary;
  final List<AdminReportRevenuePoint> weeklyRevenue;
  final List<AdminReportCategory> categories;
  final List<AdminReportVendor> vendors;

  factory AdminReportsData.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'];
    final weeklyRevenueJson = json['weekly_revenue'];
    final categoriesJson = json['categories'];
    final vendorsJson = json['vendors'];

    return AdminReportsData(
      summary: summaryJson is Map
          ? AdminReportSummary.fromJson(Map<String, dynamic>.from(summaryJson))
          : const AdminReportSummary.empty(),
      weeklyRevenue: weeklyRevenueJson is List
          ? weeklyRevenueJson
                .map(
                  (item) => AdminReportRevenuePoint.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const <AdminReportRevenuePoint>[],
      categories: categoriesJson is List
          ? categoriesJson
                .map(
                  (item) => AdminReportCategory.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const <AdminReportCategory>[],
      vendors: vendorsJson is List
          ? vendorsJson
                .map(
                  (item) => AdminReportVendor.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const <AdminReportVendor>[],
    );
  }
}

class AdminReportService {
  static String get baseUrl => AuthService.baseUrl;

  Future<AdminReportsData> getReports() async {
    final response = await http.get(Uri.parse('$baseUrl/get_admin_reports.php'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load admin reports (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Invalid admin reports response');
    }

    return AdminReportsData.fromJson(decoded);
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
