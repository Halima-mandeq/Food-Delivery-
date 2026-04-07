class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final double rating;
  final double deliveryFee;
  final String deliveryTime;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.deliveryFee,
    required this.deliveryTime,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      rating: double.parse(json['rating']?.toString() ?? '4.5'),
      deliveryFee: double.parse(json['delivery_fee']?.toString() ?? '0.0'),
      deliveryTime: json['delivery_time'] ?? '20-30 min',
      isAvailable: _parseAvailability(json['is_available']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'rating': rating,
      'delivery_fee': deliveryFee,
      'delivery_time': deliveryTime,
      'is_available': isAvailable,
    };
  }

  static bool _parseAvailability(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'active';
  }
}
