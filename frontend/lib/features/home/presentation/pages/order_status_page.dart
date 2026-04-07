import 'package:flutter/material.dart';

import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/customer_order_model.dart';

typedef OrderStatusAction = Future<void> Function(BuildContext context);

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({
    super.key,
    required this.order,
    this.highlightNewOrder = false,
    this.interceptSystemBack = false,
    this.primaryButtonLabel = 'Track Order',
    this.secondaryButtonLabel = 'Back to Home',
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final CustomerOrderModel order;
  final bool highlightNewOrder;
  final bool interceptSystemBack;
  final String primaryButtonLabel;
  final String secondaryButtonLabel;
  final OrderStatusAction? onPrimaryAction;
  final OrderStatusAction? onSecondaryAction;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  bool _isRunningAction = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColorFor(widget.order.stage);

    return WillPopScope(
      onWillPop: () async {
        if (!widget.interceptSystemBack) {
          return true;
        }

        await _handleSecondaryAction();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3EE),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
            children: [
              _buildHeader(),
              const SizedBox(height: 26),
              _buildHeroIcon(accentColor),
              const SizedBox(height: 26),
              Text(
                _headlineText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _subtitleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7283A1),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildDeliveryCard(accentColor),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      label: 'Order ID',
                      value: widget.order.orderCode,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      label: 'Payment',
                      value: widget.order.paymentMethod,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildAddressCard(),
              const SizedBox(height: 18),
              _buildRestaurantCard(accentColor),
              const SizedBox(height: 30),
              _buildPrimaryButton(),
              const SizedBox(height: 14),
              _buildSecondaryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _handleBackPress,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            fixedSize: const Size(46, 46),
          ),
        ),
        const Expanded(
          child: Text(
            'Order Status',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 46),
      ],
    );
  }

  Widget _buildHeroIcon(Color accentColor) {
    return Center(
      child: Container(
        width: 182,
        height: 182,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _heroIcon,
            color: accentColor,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Color accentColor) {
    final activeSegments = _activeProgressSegments;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATED DELIVERY',
                      style: TextStyle(
                        color: Color(0xFF627491),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.order.estimatedDeliveryTimeDisplay,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.order.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.delivery_dining_rounded,
                color: const Color(0xFFE4E4E4),
                size: 54,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(3, (index) {
              final isActive = index < activeSegments;
              return Expanded(
                child: Container(
                  height: 7,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor
                        : accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF627491),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF6F7F97),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DELIVERY ADDRESS',
                  style: TextStyle(
                    color: Color(0xFF627491),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.order.deliveryAddress.trim().isEmpty
                      ? 'Delivery address will be confirmed with you.'
                      : widget.order.deliveryAddress.trim(),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 62,
              height: 62,
              child: _buildRestaurantImage(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.order.restaurantStatusMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7283A1),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _restaurantStatusIcon,
              color: accentColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantImage() {
    final imageUrl = widget.order.restaurantImageUrl.trim();

    if (imageUrl.isEmpty) {
      return _buildImageFallback();
    }

    if (imageUrl.startsWith('uploads/')) {
      return Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageFallback(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFFFEDE3),
      child: const Icon(
        Icons.restaurant_rounded,
        color: AppTheme.primaryColor,
        size: 30,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 76,
      child: FilledButton.icon(
        onPressed: _isRunningAction ? null : _handlePrimaryAction,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: _isRunningAction
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Icon(Icons.map_outlined, size: 22),
        label: Text(
          widget.primaryButtonLabel,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      height: 70,
      child: FilledButton(
        onPressed: _isRunningAction ? null : _handleSecondaryAction,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF0F4F8),
          foregroundColor: AppTheme.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.secondaryButtonLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (widget.onPrimaryAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your order status is up to date.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _runAction(widget.onPrimaryAction!);
  }

  Future<void> _handleSecondaryAction() async {
    if (widget.onSecondaryAction == null) {
      Navigator.of(context).maybePop();
      return;
    }

    await _runAction(widget.onSecondaryAction!);
  }

  Future<void> _runAction(OrderStatusAction action) async {
    setState(() => _isRunningAction = true);

    try {
      await action(context);
    } finally {
      if (mounted) {
        setState(() => _isRunningAction = false);
      }
    }
  }

  void _handleBackPress() {
    if (widget.interceptSystemBack) {
      _handleSecondaryAction();
      return;
    }

    Navigator.of(context).maybePop();
  }

  String get _headlineText {
    if (widget.highlightNewOrder && widget.order.isActive) {
      return 'Order Placed Successfully!';
    }

    return widget.order.statusHeadline;
  }

  String get _subtitleText {
    if (widget.highlightNewOrder && widget.order.isActive) {
      return 'Your food is on the way. You can track your order in real time.';
    }

    return widget.order.statusDescription;
  }

  IconData get _heroIcon {
    switch (widget.order.stage) {
      case CustomerOrderStage.placed:
      case CustomerOrderStage.preparing:
        return Icons.check_rounded;
      case CustomerOrderStage.onTheWay:
        return Icons.delivery_dining_rounded;
      case CustomerOrderStage.delivered:
        return Icons.done_all_rounded;
      case CustomerOrderStage.cancelled:
        return Icons.close_rounded;
    }
  }

  IconData get _restaurantStatusIcon {
    switch (widget.order.stage) {
      case CustomerOrderStage.placed:
      case CustomerOrderStage.preparing:
        return Icons.restaurant_menu_rounded;
      case CustomerOrderStage.onTheWay:
        return Icons.delivery_dining_rounded;
      case CustomerOrderStage.delivered:
        return Icons.check_circle_rounded;
      case CustomerOrderStage.cancelled:
        return Icons.cancel_rounded;
    }
  }

  int get _activeProgressSegments {
    switch (widget.order.stage) {
      case CustomerOrderStage.delivered:
        return 3;
      case CustomerOrderStage.onTheWay:
        return 2;
      case CustomerOrderStage.cancelled:
      case CustomerOrderStage.placed:
      case CustomerOrderStage.preparing:
        return 1;
    }
  }

  Color _accentColorFor(CustomerOrderStage stage) {
    switch (stage) {
      case CustomerOrderStage.placed:
      case CustomerOrderStage.preparing:
        return AppTheme.primaryColor;
      case CustomerOrderStage.onTheWay:
        return const Color(0xFFFF8A00);
      case CustomerOrderStage.delivered:
        return const Color(0xFF22A06B);
      case CustomerOrderStage.cancelled:
        return const Color(0xFFCC4B4B);
    }
  }
}
