import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/data/services/product_service.dart';
import 'package:food_delivery_frontend/features/admin/presentation/pages/add_product_page.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final ProductService _productService = ProductService();
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getProducts(includeUnavailable: true);
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _productService.getProducts(includeUnavailable: true);
    });
  }

  Future<void> _deleteProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/delete_product.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        _refreshProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Product deleted"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Menu",
          style: TextStyle(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshProducts,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          final products = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductTile(product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (result == true) {
            _refreshProducts();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductTile(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey[100],
              child: product.imageUrl.startsWith('uploads/')
                  ? Image.network(
                      "${AuthService.baseUrl.replaceAll('/api', '')}/${product.imageUrl}",
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : Image.asset(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  product.category ?? "No Category",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAvailabilityIndicator(product.isAvailable),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductPage(product: product),
                ),
              );
              if (result == true) {
                _refreshProducts();
              }
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Product"),
                  content: Text(
                    "Are you sure you want to delete '${product.name}'?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteProduct(product.id);
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityIndicator(bool isAvailable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: isAvailable
                ? const Color(0xFF95A3B8)
                : const Color(0xFFB0BCCA),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isAvailable
                ? AppTheme.primaryColor
                : const Color(0xFFD6DEE8),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: (isAvailable
                        ? AppTheme.primaryColor
                        : const Color(0xFF94A3B8))
                    .withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
