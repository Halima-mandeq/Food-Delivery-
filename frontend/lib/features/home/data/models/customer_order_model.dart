enum CustomerOrderStage { placed, preparing, onTheWay, delivered, cancelled }

class CustomerOrderModel {
  const CustomerOrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.itemsLabel,
    required this.totalItems,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.deliveryFee,
    required this.taxAmount,
    required this.paymentMethod,
    required this.status,
    required this.deliveryAddress,
    required this.estimatedDeliveryTime,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final int? restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final String itemsLabel;
  final int totalItems;
  final double totalAmount;
  final double subtotalAmount;
  final double deliveryFee;
  final double taxAmount;
  final String paymentMethod;
  final String status;
  final String deliveryAddress;
  final String estimatedDeliveryTime;
  final DateTime? createdAt;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomerOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      restaurantId: int.tryParse(json['restaurant_id']?.toString() ?? ''),
      restaurantName: json['restaurant_name']?.toString().trim().isNotEmpty == true
          ? json['restaurant_name'].toString().trim()
          : 'Restaurant',
      restaurantImageUrl: json['restaurant_image_url']?.toString().trim() ?? '',
      itemsLabel: json['items_label']?.toString().trim() ?? '',
      totalItems: int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      subtotalAmount:
          double.tryParse(json['subtotal_amount']?.toString() ?? '0') ?? 0,
      deliveryFee:
          double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0,
      paymentMethod: json['payment_method']?.toString().trim().isNotEmpty == true
          ? json['payment_method'].toString().trim()
          : 'Mastercard',
      status: json['status']?.toString().trim().isNotEmpty == true
          ? json['status'].toString().trim()
          : 'Pending',
      deliveryAddress: json['delivery_address']?.toString().trim() ?? '',
      estimatedDeliveryTime:
          json['estimated_delivery_time']?.toString().trim() ?? '25-35 min',
      createdAt: _parseDate(json['created_at']?.toString()),
    );
  }

  bool get isCompleted => _normalizedStatus == 'completed';

  bool get isCancelled => _normalizedStatus == 'cancelled';

  bool get isActive => !isCompleted && !isCancelled;

  String get orderCode => '#FE-${(9481 + id).toString()}';

  String get totalLabel => '\$${totalAmount.toStringAsFixed(2)}';

  String get itemsSummary {
    if (itemsLabel.trim().isNotEmpty) {
      return itemsLabel.trim();
    }

    if (totalItems > 0) {
      return '$totalItems item${totalItems == 1 ? '' : 's'}';
    }

    return 'Your recent order';
  }

  String get estimatedDeliveryTimeDisplay {
    final numbers = _deliveryTimeNumbers;
    if (numbers.isEmpty) {
      return estimatedDeliveryTime.trim().isEmpty
          ? '25-35 mins'
          : estimatedDeliveryTime.trim();
    }

    if (numbers.length == 1) {
      return '${numbers.first} mins';
    }

    return '${numbers.first}-${numbers.last} mins';
  }

  CustomerOrderStage get stage {
    if (isCancelled) {
      return CustomerOrderStage.cancelled;
    }

    if (isCompleted) {
      return CustomerOrderStage.delivered;
    }

    final elapsedMinutes = _elapsedMinutes;
    if (elapsedMinutes == null || elapsedMinutes < 4) {
      return CustomerOrderStage.placed;
    }

    final upperMinutes = estimatedUpperMinutes;
    if (upperMinutes == null || upperMinutes <= 0) {
      return CustomerOrderStage.preparing;
    }

    final ratio = elapsedMinutes / upperMinutes;
    if (ratio < 0.45) {
      return CustomerOrderStage.preparing;
    }

    return CustomerOrderStage.onTheWay;
  }

  String get statusLabel {
    switch (stage) {
      case CustomerOrderStage.placed:
        return 'Placed';
      case CustomerOrderStage.preparing:
        return 'Preparing';
      case CustomerOrderStage.onTheWay:
        return 'On the way';
      case CustomerOrderStage.delivered:
        return 'Delivered';
      case CustomerOrderStage.cancelled:
        return 'Cancelled';
    }
  }

  String get timeLabel {
    if (isCancelled) {
      return 'Cancelled';
    }

    if (isCompleted) {
      return _formatTimestamp(createdAt);
    }

    final remaining = remainingMinutes;
    switch (stage) {
      case CustomerOrderStage.placed:
        return 'Confirmed just now';
      case CustomerOrderStage.preparing:
        if (remaining != null && remaining > 0) {
          return 'Ready in $remaining min';
        }
        return 'Preparing now';
      case CustomerOrderStage.onTheWay:
        if (remaining != null && remaining > 0) {
          return 'Arriving in $remaining min';
        }
        return 'Driver is nearby';
      case CustomerOrderStage.delivered:
        return _formatTimestamp(createdAt);
      case CustomerOrderStage.cancelled:
        return 'Cancelled';
    }
  }

  String get statusHeadline {
    if (isCancelled) {
      return 'Order Cancelled';
    }

    if (isCompleted) {
      return 'Order Delivered';
    }

    switch (stage) {
      case CustomerOrderStage.placed:
        return 'Order Confirmed';
      case CustomerOrderStage.preparing:
        return 'Preparing Your Meal';
      case CustomerOrderStage.onTheWay:
        return 'Order On The Way';
      case CustomerOrderStage.delivered:
        return 'Order Delivered';
      case CustomerOrderStage.cancelled:
        return 'Order Cancelled';
    }
  }

  String get statusDescription {
    if (isCancelled) {
      return 'This order was cancelled before delivery.';
    }

    if (isCompleted) {
      return 'Your meal has arrived. Enjoy your food!';
    }

    switch (stage) {
      case CustomerOrderStage.placed:
        return 'The restaurant received your order and is getting started.';
      case CustomerOrderStage.preparing:
        return 'The kitchen is preparing everything fresh for you.';
      case CustomerOrderStage.onTheWay:
        return 'Your rider is heading to your delivery address now.';
      case CustomerOrderStage.delivered:
        return 'Your meal has arrived. Enjoy your food!';
      case CustomerOrderStage.cancelled:
        return 'This order was cancelled before delivery.';
    }
  }

  String get restaurantStatusMessage {
    switch (stage) {
      case CustomerOrderStage.placed:
        return 'Order accepted and queued for preparation...';
      case CustomerOrderStage.preparing:
        return 'Preparing your meal...';
      case CustomerOrderStage.onTheWay:
        return 'Your rider is bringing the order now...';
      case CustomerOrderStage.delivered:
        return 'Delivered successfully.';
      case CustomerOrderStage.cancelled:
        return 'Order cancelled.';
    }
  }

  int? get estimatedUpperMinutes {
    final numbers = _deliveryTimeNumbers;
    if (numbers.isEmpty) {
      return null;
    }
    return numbers.length == 1 ? numbers.first : numbers.last;
  }

  int? get remainingMinutes {
    final upperMinutes = estimatedUpperMinutes;
    final elapsedMinutes = _elapsedMinutes;

    if (!isActive || upperMinutes == null || elapsedMinutes == null) {
      return null;
    }

    final remaining = upperMinutes - elapsedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  String get _normalizedStatus => status.trim().toLowerCase();

  int? get _elapsedMinutes {
    final created = createdAt?.toLocal();
    if (created == null) {
      return null;
    }

    final difference = DateTime.now().toLocal().difference(created).inMinutes;
    if (difference < 0) {
      return 0;
    }

    return difference;
  }

  List<int> get _deliveryTimeNumbers {
    return RegExp(r'\d+')
        .allMatches(estimatedDeliveryTime)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .toList();
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  static String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return 'Recently updated';
    }

    final local = value.toLocal();
    final now = DateTime.now().toLocal();
    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final time = _formatClock(local);

    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return 'Today, $time';
    }

    return '${monthNames[local.month - 1]} ${local.day}, $time';
  }

  static String _formatClock(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
