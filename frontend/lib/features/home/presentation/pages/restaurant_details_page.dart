import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/data/models/menu_item_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/data/services/product_service.dart';
import 'package:food_delivery_frontend/features/home/presentation/models/cart_models.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/cart_page.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/item_details_page.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final ProductModel restaurant;
  final UserModel? user;
  final String deliveryAddress;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurant,
    this.user,
    this.deliveryAddress = '',
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  late Future<List<MenuItemModel>> _menuItemsFuture;

  final List<CartLineItem> _cartItems = <CartLineItem>[];
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  bool _isFavorite = true;
  String _selectedTab = 'Popular';

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _productService.getMenuItems(widget.restaurant.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItemModel>>(
      future: _menuItemsFuture,
      builder: (context, snapshot) {
        final items = _resolveMenuItems(snapshot.data ?? const []);
        final sections = _buildSections(items);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F5F2),
          body: SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 124),
              children: [
                _buildTopBar(),
                const SizedBox(height: 18),
                _buildHeroCard(),
                const SizedBox(height: 24),
                _buildSectionTabs(sections),
                const SizedBox(height: 22),
                for (final section in sections) ...[
                  KeyedSubtree(
                    key: _sectionKeyFor(section.tabLabel),
                    child: _buildMenuSection(section),
                  ),
                  const SizedBox(height: 28),
                ],
              ],
            ),
          ),
          bottomNavigationBar: _buildCartBar(),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildCircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            widget.restaurant.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentColor,
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
        icon: Icon(icon, color: AppTheme.accentColor, size: 24),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 310,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildRestaurantCoverImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'TOP RATED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.restaurant.deliveryTime} \u2022 ${_deliveryText(widget.restaurant.deliveryFee)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.restaurant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '(${_reviewCountLabel(widget.restaurant.id)})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\u2022 ${_addressLabel(widget.restaurant.id)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCoverImage() {
    final imageUrl = widget.restaurant.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFEDE6DE),
        child: const Center(
          child: Icon(
            Icons.restaurant_rounded,
            color: AppTheme.primaryColor,
            size: 80,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('uploads/')) {
      return Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFEDE6DE),
          child: const Center(
            child: Icon(
              Icons.restaurant_rounded,
              color: AppTheme.primaryColor,
              size: 80,
            ),
          ),
        ),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFEDE6DE),
        child: const Center(
          child: Icon(
            Icons.restaurant_rounded,
            color: AppTheme.primaryColor,
            size: 80,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTabs(List<_MenuSection> sections) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final section in sections) ...[
            InkWell(
              onTap: () => _scrollToSection(section.tabLabel),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.only(bottom: 12),
                margin: const EdgeInsets.only(right: 28),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == section.tabLabel
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2.2,
                    ),
                  ),
                ),
                child: Text(
                  section.tabLabel,
                  style: TextStyle(
                    color: _selectedTab == section.tabLabel
                        ? AppTheme.primaryColor
                        : const Color(0xFF697A95),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(_MenuSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (section.tabLabel == 'Popular') ...[
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Column(
          children: [
            for (var index = 0; index < section.items.length; index++) ...[
              _buildMenuItemCard(section.items[index]),
              if (index != section.items.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isVegetarian(item)) ...[
                    Row(
                      children: const [
                        Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF16A34A),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'VEGETARIAN',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6D7E99),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 116,
                  height: 116,
                  child: _buildMenuItemImage(item),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _addToCart(item),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _openItemDetails(item),
      child: card,
    );
  }

  Widget _buildMenuItemImage(MenuItemModel item) {
    final imageUrl = item.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF1F4F6),
        child: const Center(
          child: Icon(
            Icons.fastfood_rounded,
            color: AppTheme.primaryColor,
            size: 44,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('uploads/')) {
      return Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF1F4F6),
          child: const Center(
            child: Icon(
              Icons.fastfood_rounded,
              color: AppTheme.primaryColor,
              size: 44,
            ),
          ),
        ),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF1F4F6),
        child: const Center(
          child: Icon(
            Icons.fastfood_rounded,
            color: AppTheme.primaryColor,
            size: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    final totalItems = _cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalPrice = _cartTotal();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 98,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _openCartPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.34),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VIEW CART',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'From ${widget.restaurant.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<MenuItemModel> _resolveMenuItems(List<MenuItemModel> apiItems) {
    if (apiItems.isNotEmpty) {
      return apiItems;
    }

    return <MenuItemModel>[
      MenuItemModel(
        id: -1,
        restaurantId: widget.restaurant.id,
        name: 'Signature Wagyu Burger',
        description:
            'Premium wagyu beef, truffle aioli, aged cheddar, and caramelized onions.',
        price: 18.50,
        imageUrl: 'images/unnamed (1).png',
        category: 'Popular',
        isPopular: true,
      ),
      MenuItemModel(
        id: -2,
        restaurantId: widget.restaurant.id,
        name: 'Truffle Parmesan Fries',
        description:
            'Crispy golden fries tossed in truffle oil and freshly grated parmesan.',
        price: 9.00,
        imageUrl: 'images/unnamed (5).png',
        category: 'Sides',
        isPopular: true,
      ),
      MenuItemModel(
        id: -3,
        restaurantId: widget.restaurant.id,
        name: 'Quinoa & Avocado Bowl',
        description:
            'Organic quinoa, fresh avocado slices, cherry tomatoes, and citrus greens.',
        price: 14.25,
        imageUrl: 'images/unnamed (2).png',
        category: 'Popular',
        isPopular: true,
      ),
      MenuItemModel(
        id: -4,
        restaurantId: widget.restaurant.id,
        name: 'Honey Glazed Salmon',
        description:
            'Pan-seared Atlantic salmon with wild rice and seasonal vegetables.',
        price: 24.00,
        imageUrl: 'images/unnamed (3).png',
        category: 'Main Course',
      ),
      MenuItemModel(
        id: -5,
        restaurantId: widget.restaurant.id,
        name: 'Sparkling Citrus Soda',
        description:
            'Fresh orange, lemon zest, and sparkling water served over ice.',
        price: 5.50,
        imageUrl: 'images/unnamed (2).png',
        category: 'Drinks',
      ),
      MenuItemModel(
        id: -6,
        restaurantId: widget.restaurant.id,
        name: 'Molten Chocolate Cake',
        description:
            'Warm chocolate center, silky ganache, and vanilla cream on the side.',
        price: 11.75,
        imageUrl: 'images/unnamed.png',
        category: 'Desserts',
      ),
    ];
  }

  List<_MenuSection> _buildSections(List<MenuItemModel> items) {
    final popularItems = items.where((item) => item.isPopular).toList();
    final featuredItems = popularItems.isNotEmpty
        ? popularItems
        : items.take(3).toList();
    final featuredIds = featuredItems.map((item) => item.id).toSet();

    final groupedItems = <String, List<MenuItemModel>>{};
    for (final item in items) {
      if (featuredIds.contains(item.id)) {
        continue;
      }

      final category = _displayCategory(item.category);
      groupedItems.putIfAbsent(category, () => <MenuItemModel>[]).add(item);
    }

    final sections = <_MenuSection>[
      if (featuredItems.isNotEmpty)
        _MenuSection(
          tabLabel: 'Popular',
          title: 'Popular Items',
          items: featuredItems,
        ),
    ];

    const preferredOrder = <String>[
      'Main Course',
      'Drinks',
      'Desserts',
      'Sides',
    ];

    for (final label in preferredOrder) {
      final sectionItems = groupedItems.remove(label);
      if (sectionItems != null && sectionItems.isNotEmpty) {
        sections.add(
          _MenuSection(tabLabel: label, title: label, items: sectionItems),
        );
      }
    }

    final remainingLabels = groupedItems.keys.toList()..sort();
    for (final label in remainingLabels) {
      final sectionItems = groupedItems[label]!;
      if (sectionItems.isNotEmpty) {
        sections.add(
          _MenuSection(tabLabel: label, title: label, items: sectionItems),
        );
      }
    }

    return sections;
  }

  GlobalKey _sectionKeyFor(String label) {
    return _sectionKeys.putIfAbsent(label, GlobalKey.new);
  }

  Future<void> _scrollToSection(String label) async {
    setState(() => _selectedTab = label);
    final targetContext = _sectionKeyFor(label).currentContext;
    if (targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _addToCart(MenuItemModel item) {
    _addOrUpdateCartItem(item: item, quantity: 1, unitPrice: item.price);
    _openCartPage();
  }

  Future<void> _openItemDetails(MenuItemModel item) async {
    final result = await Navigator.push<ItemDetailsResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItemDetailsPage(item: item, restaurantName: widget.restaurant.name),
      ),
    );

    if (!mounted || result == null || result.quantity <= 0) {
      return;
    }

    _addOrUpdateCartItem(
      item: item,
      quantity: result.quantity,
      unitPrice: result.unitPrice,
      selectedOptions: result.selectedOptions,
      notes: result.notes,
    );

    await _openCartPage();
  }

  void _addOrUpdateCartItem({
    required MenuItemModel item,
    required int quantity,
    required double unitPrice,
    List<CartCustomizationOption> selectedOptions =
        const <CartCustomizationOption>[],
    String notes = '',
  }) {
    final signature = _cartSignatureFor(item.id, selectedOptions, notes);

    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (cartItem) => cartItem.id == signature,
      );

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += quantity;
        return;
      }

      _cartItems.add(
        CartLineItem(
          id: signature,
          item: item,
          unitPrice: unitPrice,
          quantity: quantity,
          selectedOptions: selectedOptions,
          notes: notes,
        ),
      );
    });
  }

  double _cartTotal() {
    return _cartItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  String _cartSignatureFor(
    int itemId,
    List<CartCustomizationOption> selectedOptions,
    String notes,
  ) {
    final optionKey = selectedOptions
        .map(
          (option) => '${option.title}:${option.priceDelta.toStringAsFixed(2)}',
        )
        .join('|');
    return '$itemId|$optionKey|${notes.trim()}';
  }

  Future<void> _openCartPage() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a few items to build your cart.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          restaurant: widget.restaurant,
          user: widget.user,
          deliveryAddress: widget.deliveryAddress,
          cartItems: _cartItems,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  bool _isVegetarian(MenuItemModel item) {
    final text = '${item.name} ${item.description} ${item.category}'
        .toLowerCase();
    return text.contains('vegetarian') ||
        text.contains('quinoa') ||
        text.contains('salad') ||
        text.contains('avocado') ||
        text.contains('veggie');
  }

  String _displayCategory(String rawCategory) {
    final normalized = rawCategory.trim().toLowerCase();

    switch (normalized) {
      case 'main course':
      case 'main_course':
      case 'entree':
      case 'entrees':
        return 'Main Course';
      case 'drink':
      case 'drinks':
      case 'beverage':
      case 'beverages':
        return 'Drinks';
      case 'dessert':
      case 'desserts':
        return 'Desserts';
      case 'side':
      case 'sides':
        return 'Sides';
      default:
        return _titleCase(
          rawCategory.trim().isEmpty ? 'Menu' : rawCategory.trim(),
        );
    }
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _deliveryText(double deliveryFee) {
    return deliveryFee <= 0
        ? 'Free Delivery'
        : '\$${deliveryFee.toStringAsFixed(2)} Delivery';
  }

  String _reviewCountLabel(int seed) {
    const reviews = <String>[
      '500+ reviews',
      '320+ reviews',
      '210+ reviews',
      '640+ reviews',
      '180+ reviews',
    ];
    return reviews[seed.abs() % reviews.length];
  }

  String _addressLabel(int seed) {
    const addresses = <String>[
      '123 Gourmet St.',
      '48 Riverside Ave.',
      '21 Market Lane',
      '77 Sunset Blvd.',
      '15 Maple Street',
    ];
    return addresses[seed.abs() % addresses.length];
  }
}

class _MenuSection {
  final String tabLabel;
  final String title;
  final List<MenuItemModel> items;

  const _MenuSection({
    required this.tabLabel,
    required this.title,
    required this.items,
  });
}
