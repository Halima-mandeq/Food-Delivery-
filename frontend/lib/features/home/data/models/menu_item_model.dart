class MenuItemModel {
  final int id;
  final int restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isPopular;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isPopular = false,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: int.parse(json['id'].toString()),
      restaurantId: int.parse(json['restaurant_id'].toString()),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      isPopular: json['is_popular'] == 1 || json['is_popular'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_popular': isPopular,
    };
  }
}
