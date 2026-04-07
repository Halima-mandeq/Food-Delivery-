import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/menu_item_model.dart';
import 'package:food_delivery_frontend/features/home/presentation/models/cart_models.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({
    super.key,
    required this.item,
    required this.restaurantName,
  });

  final MenuItemModel item;
  final String restaurantName;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  late final TextEditingController _notesController;
  late final List<_CustomizationOption> _options;
  final Set<String> _selectedOptionIds = <String>{};

  int _quantity = 1;
  bool _isFavorite = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _options = _buildOptions(widget.item);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _optionsTotal {
    return _options
        .where((option) => _selectedOptionIds.contains(option.id))
        .fold<double>(0, (sum, option) => sum + option.priceDelta);
  }

  List<CartCustomizationOption> get _selectedOptions {
    return _options
        .where((option) => _selectedOptionIds.contains(option.id))
        .map(
          (option) => CartCustomizationOption(
            title: option.title,
            priceDelta: option.priceDelta,
          ),
        )
        .toList();
  }

  double get _totalPrice => (widget.item.price + _optionsTotal) * _quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopBar(),
            const SizedBox(height: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [_buildHeroImage(), const SizedBox(height: 178)],
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: _buildSummaryCard(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSectionHeader(
                title: 'Customize Your Meal',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Optional',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  for (var index = 0; index < _options.length; index++) ...[
                    _buildOptionTile(_options[index]),
                    if (index != _options.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildInstructionsCard(),
            ),
            const SizedBox(height: 124),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Item Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          _buildCircleButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            onTap: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
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
            color: const Color(0xFF182740).withValues(alpha: 0.06),
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

  Widget _buildHeroImage() {
    return Container(
      height: 408,
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF0ECE6)],
        ),
      ),
      child: Center(
        child: SizedBox(width: double.infinity, child: _buildFoodImage()),
      ),
    );
  }

  Widget _buildFoodImage() {
    final imageUrl = widget.item.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.fastfood_rounded,
        color: AppTheme.primaryColor,
        size: 96,
      );
    }

    if (imageUrl.startsWith('uploads/')) {
      return Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.fastfood_rounded,
          color: AppTheme.primaryColor,
          size: 96,
        ),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.fastfood_rounded,
        color: AppTheme.primaryColor,
        size: 96,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6E2E),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.item.isPopular ? 'CHEF\'S CHOICE' : _eyebrowLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${widget.item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.item.description.isEmpty
                ? 'Freshly prepared at ${widget.restaurantName} with premium ingredients.'
                : widget.item.description,
            style: const TextStyle(
              color: Color(0xFF697A95),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFFF0EBE5)),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'QUANTITY',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              _buildQuantityStepper(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildQuantityButton(
            icon: Icons.remove_rounded,
            onTap: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add_rounded,
            onTap: () => setState(() => _quantity += 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          icon,
          color: onTap == null
              ? const Color(0xFFB8C2D3)
              : AppTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF627491),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildOptionTile(_CustomizationOption option) {
    final isSelected = _selectedOptionIds.contains(option.id);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _toggleOption(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.28)
                : Colors.transparent,
            width: 1.4,
          ),
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
                color: option.iconBackgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(option.icon, color: option.iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.priceDelta <= 0
                        ? 'FREE'
                        : '+ \$${option.priceDelta.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: option.priceDelta <= 0
                          ? const Color(0xFF7A8BA6)
                          : const Color(0xFF8293AE),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFD8E0EA),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          const Row(
            children: [
              Icon(
                Icons.short_text_rounded,
                color: Color(0xFF7586A1),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'SPECIAL INSTRUCTIONS',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              minLines: 4,
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'E.g. Sauce on the side...',
                hintStyle: TextStyle(
                  color: Color(0xFF95A4BA),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EE),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF152238).withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          height: 70,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(
              context,
              ItemDetailsResult(
                quantity: _quantity,
                unitPrice: widget.item.price + _optionsTotal,
                selectedOptions: _selectedOptions,
                notes: _notesController.text.trim(),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6E2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined, size: 24),
            label: Text(
              'Add to Cart - \$${_totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleOption(String optionId) {
    setState(() {
      if (_selectedOptionIds.contains(optionId)) {
        _selectedOptionIds.remove(optionId);
      } else {
        _selectedOptionIds.add(optionId);
      }
    });
  }

  String _eyebrowLabel() {
    final category = widget.item.category.trim();
    if (category.isEmpty) {
      return 'SIGNATURE ITEM';
    }

    return category.toUpperCase();
  }

  List<_CustomizationOption> _buildOptions(MenuItemModel item) {
    final text = '${item.name} ${item.description} ${item.category}'
        .toLowerCase();

    if (text.contains('burger') ||
        text.contains('wagyu') ||
        text.contains('beef')) {
      return const [
        _CustomizationOption(
          id: 'extra_cheddar',
          title: 'Extra Aged Cheddar',
          priceDelta: 2.00,
          icon: Icons.restaurant_menu_rounded,
          iconColor: AppTheme.primaryColor,
          iconBackgroundColor: Color(0xFFFFF2E8),
        ),
        _CustomizationOption(
          id: 'no_onions',
          title: 'No Caramelized Onions',
          priceDelta: 0,
          icon: Icons.block_rounded,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
        _CustomizationOption(
          id: 'sauce_side',
          title: 'Sauce on the Side',
          priceDelta: 0,
          icon: Icons.local_dining_rounded,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
      ];
    }

    if (text.contains('pizza')) {
      return const [
        _CustomizationOption(
          id: 'extra_mozzarella',
          title: 'Extra Mozzarella',
          priceDelta: 1.75,
          icon: Icons.restaurant_menu_rounded,
          iconColor: AppTheme.primaryColor,
          iconBackgroundColor: Color(0xFFFFF2E8),
        ),
        _CustomizationOption(
          id: 'thin_crust',
          title: 'Thin Crust',
          priceDelta: 0,
          icon: Icons.change_circle_outlined,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
        _CustomizationOption(
          id: 'cut_squares',
          title: 'Cut into Squares',
          priceDelta: 0,
          icon: Icons.grid_view_rounded,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
      ];
    }

    if (text.contains('drink') ||
        text.contains('soda') ||
        text.contains('juice')) {
      return const [
        _CustomizationOption(
          id: 'large_size',
          title: 'Upgrade to Large',
          priceDelta: 1.50,
          icon: Icons.local_cafe_rounded,
          iconColor: AppTheme.primaryColor,
          iconBackgroundColor: Color(0xFFFFF2E8),
        ),
        _CustomizationOption(
          id: 'less_ice',
          title: 'Less Ice',
          priceDelta: 0,
          icon: Icons.ac_unit_rounded,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
        _CustomizationOption(
          id: 'no_straw',
          title: 'No Straw',
          priceDelta: 0,
          icon: Icons.block_rounded,
          iconColor: Color(0xFF6B7B95),
          iconBackgroundColor: Color(0xFFF0F4F8),
        ),
      ];
    }

    return const [
      _CustomizationOption(
        id: 'extra_portion',
        title: 'Extra Portion',
        priceDelta: 2.50,
        icon: Icons.add_circle_outline_rounded,
        iconColor: AppTheme.primaryColor,
        iconBackgroundColor: Color(0xFFFFF2E8),
      ),
      _CustomizationOption(
        id: 'no_spice',
        title: 'No Extra Spice',
        priceDelta: 0,
        icon: Icons.block_rounded,
        iconColor: Color(0xFF6B7B95),
        iconBackgroundColor: Color(0xFFF0F4F8),
      ),
      _CustomizationOption(
        id: 'utensils',
        title: 'Include Cutlery',
        priceDelta: 0,
        icon: Icons.flatware_rounded,
        iconColor: Color(0xFF6B7B95),
        iconBackgroundColor: Color(0xFFF0F4F8),
      ),
    ];
  }
}

class _CustomizationOption {
  const _CustomizationOption({
    required this.id,
    required this.title,
    required this.priceDelta,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });

  final String id;
  final String title;
  final double priceDelta;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
}
