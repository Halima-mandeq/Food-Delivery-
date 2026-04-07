import 'package:food_delivery_frontend/features/home/data/models/menu_item_model.dart';

class CartCustomizationOption {
  const CartCustomizationOption({
    required this.title,
    required this.priceDelta,
  });

  final String title;
  final double priceDelta;
}

class CartLineItem {
  CartLineItem({
    required this.id,
    required this.item,
    required this.unitPrice,
    required this.quantity,
    this.selectedOptions = const <CartCustomizationOption>[],
    this.notes = '',
  });

  final String id;
  final MenuItemModel item;
  final double unitPrice;
  final List<CartCustomizationOption> selectedOptions;
  final String notes;
  int quantity;

  double get lineTotal => unitPrice * quantity;
}

class ItemDetailsResult {
  const ItemDetailsResult({
    required this.quantity,
    required this.unitPrice,
    this.selectedOptions = const <CartCustomizationOption>[],
    this.notes = '',
  });

  final int quantity;
  final double unitPrice;
  final List<CartCustomizationOption> selectedOptions;
  final String notes;

  double get totalPrice => unitPrice * quantity;
}
