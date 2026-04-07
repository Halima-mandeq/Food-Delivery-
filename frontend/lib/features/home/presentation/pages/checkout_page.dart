import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/data/services/order_service.dart';
import 'package:food_delivery_frontend/features/home/presentation/models/cart_models.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/home_page.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/order_status_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.restaurant,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    this.user,
    this.initialDeliveryAddress = '',
  });

  final ProductModel restaurant;
  final List<CartLineItem> cartItems;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final UserModel? user;
  final String initialDeliveryAddress;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const String _evcMerchantNumber = '619896709';

  final OrderService _orderService = OrderService();
  final TextEditingController _cardholderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();

  _PaymentMethod _selectedMethod = _PaymentMethod.mastercard;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _deliveryAddressController.text = widget.initialDeliveryAddress;
  }

  @override
  void dispose() {
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  int get _itemCount {
    return widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  String get _evcAmount {
    return widget.total.toStringAsFixed(0);
  }

  String get _evcUssdCode {
    return '*712*$_evcMerchantNumber*$_evcAmount#';
  }

  String get _evcDialerUrl {
    return 'tel:${Uri.encodeComponent(_evcUssdCode)}';
  }

  String get _selectedPaymentLabel {
    return _selectedMethod == _PaymentMethod.mastercard ? 'Mastercard' : 'EVC';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 132),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildIntroCard(),
            const SizedBox(height: 26),
            const Text(
              'PAYMENT METHOD',
              style: TextStyle(
                color: Color(0xFF627491),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(
              method: _PaymentMethod.mastercard,
              title: 'Mastercard',
              subtitle: 'Pay with debit or credit card',
              icon: Icons.credit_card_rounded,
              accentColor: const Color(0xFFFF6E2E),
            ),
            const SizedBox(height: 14),
            _buildPaymentMethodCard(
              method: _PaymentMethod.evc,
              title: 'EVC',
              subtitle: 'Pay using your mobile wallet',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: const Color(0xFF22A06B),
            ),
            const SizedBox(height: 18),
            _selectedMethod == _PaymentMethod.mastercard
                ? _buildMastercardForm()
                : _buildEvcForm(),
            const SizedBox(height: 26),
            const Text(
              'DELIVERY ADDRESS',
              style: TextStyle(
                color: Color(0xFF627491),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeliveryAddressCard(),
            const SizedBox(height: 26),
            const Text(
              'ORDER TOTAL',
              style: TextStyle(
                color: Color(0xFF627491),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayBar(),
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
            'Checkout',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        _buildCircleButton(icon: Icons.lock_outline_rounded, onTap: () {}),
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

  Widget _buildIntroCard() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_itemCount item${_itemCount == 1 ? '' : 's'} ready for payment',
                  style: const TextStyle(
                    color: Color(0xFF6F8099),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required _PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _handlePaymentMethodTap(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE3E9F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172B4D).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF70819C),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.white,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFD2DCE8),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMastercardForm() {
    return _buildFormCard(
      title: 'Card Details',
      child: Column(
        children: [
          _buildInputField(
            controller: _cardholderController,
            label: 'Cardholder Name',
            hintText: 'Name on card',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _cardNumberController,
            label: 'Card Number',
            hintText: '5555 4444 3333 1111',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _expiryController,
                  label: 'Expiry Date',
                  hintText: 'MM/YY',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: _cvvController,
                  label: 'CVV',
                  hintText: '123',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvcForm() {
    return _buildFormCard(
      title: 'EVC Payment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF22A06B),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap the button below to open the phone dialer and confirm the payment using EVC.',
                    style: TextStyle(
                      color: Color(0xFF5C7D6A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildEvcCodeRow(label: 'Merchant Number', value: _evcMerchantNumber),
          const SizedBox(height: 16),
          _buildEvcCodeRow(label: 'Amount', value: _evcAmount),
          const SizedBox(height: 16),
          _buildEvcCodeRow(
            label: 'USSD Code',
            value: _evcUssdCode,
            emphasized: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _launchEvcDialer,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22A06B),
                side: const BorderSide(color: Color(0xFF22A06B)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.phone_in_talk_rounded),
              label: const Text(
                'Open EVC Dialer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    return _buildFormCard(
      title: 'Where should we deliver?',
      child: TextField(
        controller: _deliveryAddressController,
        minLines: 2,
        maxLines: 3,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Enter your street, area, and any delivery note',
          hintStyle: const TextStyle(
            color: Color(0xFF93A3B9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFF3F6FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEvcCodeRow({
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFEEF7F1) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF70819C),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFF22A06B)
                  : AppTheme.accentColor,
              fontSize: emphasized ? 18 : 16,
              fontWeight: FontWeight.w900,
              letterSpacing: emphasized ? -0.2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF93A3B9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF3F6FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
          _buildSummaryRow('Items', widget.subtotal),
          const SizedBox(height: 16),
          _buildSummaryRow('Delivery Fee', widget.deliveryFee),
          const SizedBox(height: 16),
          _buildSummaryRow('Tax', widget.tax),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0ECE6)),
          const SizedBox(height: 20),
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
                '\$${widget.total.toStringAsFixed(2)}',
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPayBar() {
    final methodLabel = _selectedMethod == _PaymentMethod.mastercard
        ? 'Pay with Mastercard'
        : 'Pay with EVC';

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
            onPressed: _isSubmitting ? null : _submitPayment,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    '$methodLabel - \$${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final error = _validatePayment();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final user = widget.user;
    if (user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again before placing your order.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_selectedMethod == _PaymentMethod.evc) {
        await _launchEvcDialer();
      }

      final placedOrder = await _orderService.placeOrder(
        user: user!,
        restaurant: widget.restaurant,
        cartItems: widget.cartItems,
        deliveryFee: widget.deliveryFee,
        taxAmount: widget.tax,
        paymentMethod: _selectedPaymentLabel,
        deliveryAddress: _deliveryAddressController.text.trim(),
      );

      widget.cartItems.clear();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusPage(
            order: placedOrder,
            highlightNewOrder: true,
            interceptSystemBack: true,
            primaryButtonLabel: 'Track Order',
            secondaryButtonLabel: 'Back to Home',
            onPrimaryAction: (pageContext) async {
              Navigator.of(pageContext).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      HomePage(user: widget.user, initialBottomIndex: 2),
                ),
                (route) => false,
              );
            },
            onSecondaryAction: (pageContext) async {
              Navigator.of(pageContext).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validatePayment() {
    if (_deliveryAddressController.text.trim().isEmpty) {
      return 'Enter a delivery address.';
    }

    if (_selectedMethod == _PaymentMethod.mastercard) {
      final name = _cardholderController.text.trim();
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiry = _expiryController.text.trim();
      final cvv = _cvvController.text.trim();

      if (name.isEmpty) {
        return 'Enter the cardholder name.';
      }
      if (cardNumber.length != 16) {
        return 'Enter a valid 16-digit card number.';
      }
      if (!_isValidExpiry(expiry)) {
        return 'Enter a valid expiry date in MM/YY format.';
      }
      if (cvv.length != 3) {
        return 'Enter a valid 3-digit CVV.';
      }
      return null;
    }

    return null;
  }

  Future<void> _handlePaymentMethodTap(_PaymentMethod method) async {
    setState(() => _selectedMethod = method);

    if (method == _PaymentMethod.evc) {
      await _launchEvcDialer();
    }
  }

  Future<void> _launchEvcDialer() async {
    final launched = await launchUrlString(
      _evcDialerUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialer. Use this code: $_evcUssdCode'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isValidExpiry(String value) {
    final match = RegExp(r'^\d{2}/\d{2}$').firstMatch(value);
    if (match == null) {
      return false;
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    return month >= 1 && month <= 12;
  }
}

enum _PaymentMethod { mastercard, evc }

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index == 2) {
        buffer.write('/');
      }
      buffer.write(digits[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
