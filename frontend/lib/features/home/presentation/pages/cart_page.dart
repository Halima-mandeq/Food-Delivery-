import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/presentation/models/cart_models.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.restaurant,
    required this.cartItems,
    this.user,
    this.deliveryAddress = '',
  });

  final ProductModel restaurant;
  final List<CartLineItem> cartItems;
  final UserModel? user;
  final String deliveryAddress;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  int get _totalItems {
    return widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get _subtotal {
    return widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
  }

  double get _deliveryFee {
    return widget.cartItems.isEmpty ? 0 : widget.restaurant.deliveryFee;
  }

  double get _tax {
    return (_subtotal * 0.055 * 100).roundToDouble() / 100;
  }

  double get _total {
    return _subtotal + _deliveryFee + _tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            if (widget.cartItems.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              for (var index = 0; index < widget.cartItems.length; index++) ...[
                _buildCartCard(widget.cartItems[index]),
                if (index != widget.cartItems.length - 1)
                  const SizedBox(height: 22),
              ],
              const SizedBox(height: 24),
              _buildPromoCard(),
              const SizedBox(height: 26),
              const Text(
                'ORDER SUMMARY',
                style: TextStyle(
                  color: Color(0xFF627491),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              _buildSummaryCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildCircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'My Cart',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCircleButton(icon: Icons.shopping_bag_outlined, onTap: () {}),
            if (_totalItems > 0)
              Positioned(
                right: -1,
                top: -3,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$_totalItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppTheme.primaryColor,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add something delicious from ${widget.restaurant.name} to get started.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F8099),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard(CartLineItem cartItem) {
    return Container(
      padding: const EdgeInsets.all(22),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 102,
                  height: 102,
                  child: _buildItemImage(cartItem),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartItem.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${cartItem.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuantityStepper(cartItem),
                  ],
                ),
              ),
            ],
          ),
          if (cartItem.selectedOptions.isNotEmpty ||
              cartItem.notes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0ECE6)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in cartItem.selectedOptions)
                  _buildOptionChip(option),
                if (cartItem.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF70819C),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            cartItem.notes,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF70819C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemImage(CartLineItem cartItem) {
    final imageUrl = cartItem.item.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF2F5F7),
        child: const Center(
          child: Icon(
            Icons.fastfood_rounded,
            color: AppTheme.primaryColor,
            size: 42,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('uploads/')) {
      return Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF2F5F7),
          child: const Center(
            child: Icon(
              Icons.fastfood_rounded,
              color: AppTheme.primaryColor,
              size: 42,
            ),
          ),
        ),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF2F5F7),
        child: const Center(
          child: Icon(
            Icons.fastfood_rounded,
            color: AppTheme.primaryColor,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(CartLineItem cartItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton(
            icon: Icons.remove_rounded,
            onTap: () => _changeQuantity(cartItem, -1),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${cartItem.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildStepperButton(
            icon: Icons.add_rounded,
            onTap: () => _changeQuantity(cartItem, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172B4D).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
    );
  }

  Widget _buildOptionChip(CartCustomizationOption option) {
    final label = option.priceDelta > 0
        ? '${option.title} (+\$${option.priceDelta.toStringAsFixed(2)})'
        : option.title;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            option.priceDelta > 0
                ? Icons.check_circle_rounded
                : Icons.do_not_disturb_on_rounded,
            color: const Color(0xFF6B7C98),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7C98),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(
            Icons.local_offer_outlined,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _promoController,
              decoration: const InputDecoration(
                hintText: 'Promo Code',
                hintStyle: TextStyle(
                  color: Color(0xFF91A1B8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          FilledButton(
            onPressed: _showPromoMessage,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
        children: [
          _buildSummaryRow('Subtotal', _subtotal),
          const SizedBox(height: 18),
          _buildSummaryRow('Delivery Fee', _deliveryFee),
          const SizedBox(height: 18),
          _buildSummaryRow('Tax', _tax),
          const SizedBox(height: 22),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0ECE6)),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF70819C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172B4D).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          height: 72,
          child: FilledButton(
            onPressed: widget.cartItems.isEmpty ? null : _openCheckoutPage,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: const Color(0xFFFFD3BC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeQuantity(CartLineItem cartItem, int delta) {
    setState(() {
      cartItem.quantity += delta;
      if (cartItem.quantity <= 0) {
        widget.cartItems.remove(cartItem);
      }
    });
  }

  void _showPromoMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promo code support is ready for the next step.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCheckoutPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          restaurant: widget.restaurant,
          user: widget.user,
          initialDeliveryAddress: widget.deliveryAddress,
          cartItems: widget.cartItems,
          subtotal: _subtotal,
          deliveryFee: _deliveryFee,
          tax: _tax,
          total: _total,
        ),
      ),
    );
  }
}
