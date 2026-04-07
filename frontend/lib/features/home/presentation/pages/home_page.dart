import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:food_delivery_frontend/features/home/data/models/customer_order_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/home_promotion_model.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/data/services/order_service.dart';
import 'package:food_delivery_frontend/features/home/data/services/product_service.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/order_status_page.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/profile_info_page.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/restaurant_details_page.dart';
import 'package:food_delivery_frontend/features/home/presentation/widgets/customer_profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.user, this.initialBottomIndex = 0});

  final UserModel? user;
  final int initialBottomIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ProductModel>> _productsFuture;
  late Future<List<CustomerOrderModel>> _ordersFuture;
  late List<_CategoryChipData> _categories;
  late _HomeBannerData _promoBanner;
  late List<_HomeOfferData> _specialOffers;
  UserModel? _currentUser;

  late int _selectedBottomIndex;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<_CategoryChipData> _fallbackCategories = [
    _CategoryChipData(label: 'All', icon: Icons.dashboard_customize_rounded),
    _CategoryChipData(label: 'Pizza', icon: Icons.local_pizza_rounded),
    _CategoryChipData(label: 'Burger', icon: Icons.lunch_dining_rounded),
    _CategoryChipData(label: 'Sushi', icon: Icons.set_meal_rounded),
    _CategoryChipData(label: 'Desserts', icon: Icons.icecream_rounded),
    _CategoryChipData(label: 'Noodles', icon: Icons.ramen_dining),
  ];

  static const _HomeBannerData _fallbackPromoBanner = _HomeBannerData(
    title: '30% OFF',
    subtitle: 'On your first 3 orders',
    ctaLabel: 'ORDER NOW',
    icon: Icons.shopping_bag_rounded,
  );

  static const List<_HomeOfferData> _fallbackSpecialOffers = [
    _HomeOfferData(
      title: 'Buy 1 Get 1',
      subtitle: 'Selected items',
      icon: Icons.sell_rounded,
      backgroundColor: Color(0xFFFFEFEA),
      iconBackgroundColor: AppTheme.primaryColor,
    ),
    _HomeOfferData(
      title: 'Free Deliv.',
      subtitle: 'Orders > \$40',
      icon: Icons.delivery_dining_rounded,
      backgroundColor: Color(0xFFFFF0D8),
      iconBackgroundColor: Color(0xFFFF8A00),
    ),
  ];

  static const List<_RestaurantCardData> _fallbackRestaurants = [
    _RestaurantCardData(
      title: 'Bella Italia Pizzeria',
      subtitle: 'Italian \u2022 Pizzas \u2022 Pasta',
      rating: 4.8,
      deliveryTime: '20-30 min',
      distanceLabel: '1.2 km',
      priceLabel: '\$12',
      badges: ['FREE DELIVERY', 'PROMO AVAILABLE'],
      assetPath: 'images/unnamed.png',
    ),
    _RestaurantCardData(
      title: 'The Burger Hub',
      subtitle: 'American \u2022 Burgers \u2022 Fast Food',
      rating: 4.5,
      deliveryTime: '15-25 min',
      distanceLabel: '2.5 km',
      priceLabel: '\$14',
      badges: ['TOP RATED'],
      assetPath: 'images/unnamed (1).png',
    ),
    _RestaurantCardData(
      title: 'Sakura Sushi Bar',
      subtitle: 'Japanese \u2022 Sushi \u2022 Ramen',
      rating: 4.9,
      deliveryTime: '35-45 min',
      distanceLabel: '3.1 km',
      priceLabel: '\$24',
      badges: ['CHEF SPECIAL'],
      assetPath: 'images/unnamed (4).png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _selectedBottomIndex = widget.initialBottomIndex.clamp(0, 3).toInt();
    _categories = List<_CategoryChipData>.from(_fallbackCategories);
    _promoBanner = _fallbackPromoBanner;
    _specialOffers = List<_HomeOfferData>.from(_fallbackSpecialOffers);
    _productsFuture = _loadFeaturedProducts();
    _ordersFuture = _loadCustomerOrders();
    _loadHomeContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    final productFuture = _loadFeaturedProducts();
    final ordersFuture = _loadCustomerOrders();
    setState(() {
      _productsFuture = productFuture;
      _ordersFuture = ordersFuture;
    });
    await Future.wait<dynamic>([
      productFuture,
      ordersFuture,
      _loadHomeContent(),
    ]);
  }

  Future<List<ProductModel>> _loadFeaturedProducts() {
    return _productService.getProducts(featuredOnly: true);
  }

  Future<List<CustomerOrderModel>> _loadCustomerOrders() {
    final userId = _currentUser?.id;
    if (userId == null) {
      return Future.value(const <CustomerOrderModel>[]);
    }

    return _orderService.getOrdersForUser(userId);
  }

  Future<void> _refreshCustomerOrders() async {
    final ordersFuture = _loadCustomerOrders();
    setState(() => _ordersFuture = ordersFuture);
    await ordersFuture;
  }

  Future<void> _loadHomeContent() async {
    final results = await Future.wait<dynamic>([
      _productService.getCategories(),
      _productService.getHomePromotions(),
    ]);

    if (!mounted) {
      return;
    }

    final categoryNames = results[0] as List<String>;
    final promotions = results[1] as List<HomePromotionModel>;

    setState(() {
      _categories = _buildCategoryChips(categoryNames);
      _promoBanner = _buildPromoBannerData(promotions);
      _specialOffers = _buildOfferCards(promotions);
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  void _updateSearch(String value) {
    setState(() => _searchQuery = value.trim());
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'All';
      _searchQuery = '';
    });
  }

  String get _deliveryAddress => 'Mogadishu, Somalia';

  List<_CategoryChipData> _buildCategoryChips(List<String> names) {
    if (names.isEmpty) {
      return List<_CategoryChipData>.from(_fallbackCategories);
    }

    final chips = <_CategoryChipData>[
      const _CategoryChipData(
        label: 'All',
        icon: Icons.dashboard_customize_rounded,
      ),
    ];
    final seen = <String>{'all'};

    for (final rawName in names) {
      final label = _normalizeCategoryLabel(rawName);
      if (label.isEmpty) {
        continue;
      }

      final normalizedKey = label.toLowerCase();
      if (seen.add(normalizedKey)) {
        chips.add(
          _CategoryChipData(label: label, icon: _iconForCategory(label)),
        );
      }
    }

    return chips.take(6).toList();
  }

  _HomeBannerData _buildPromoBannerData(List<HomePromotionModel> promotions) {
    for (final promotion in promotions) {
      if (promotion.kind.toLowerCase() == 'banner') {
        return _HomeBannerData(
          title: promotion.title.isEmpty
              ? _fallbackPromoBanner.title
              : promotion.title,
          subtitle: promotion.subtitle.isEmpty
              ? _fallbackPromoBanner.subtitle
              : promotion.subtitle,
          ctaLabel: promotion.ctaLabel.isEmpty
              ? _fallbackPromoBanner.ctaLabel
              : promotion.ctaLabel,
          icon: _iconForPromotion(
            promotion.iconKey,
            fallback: _fallbackPromoBanner.icon,
          ),
        );
      }
    }

    return _fallbackPromoBanner;
  }

  List<_HomeOfferData> _buildOfferCards(List<HomePromotionModel> promotions) {
    final offers = <_HomeOfferData>[];
    var offerIndex = 0;

    for (final promotion in promotions) {
      if (promotion.kind.toLowerCase() != 'offer') {
        continue;
      }

      final useWarmAccent = offerIndex.isEven;
      offers.add(
        _HomeOfferData(
          title: promotion.title,
          subtitle: promotion.subtitle,
          icon: _iconForPromotion(
            promotion.iconKey,
            fallback: useWarmAccent
                ? Icons.sell_rounded
                : Icons.delivery_dining_rounded,
          ),
          backgroundColor: useWarmAccent
              ? const Color(0xFFFFEFEA)
              : const Color(0xFFFFF0D8),
          iconBackgroundColor: useWarmAccent
              ? AppTheme.primaryColor
              : const Color(0xFFFF8A00),
        ),
      );
      offerIndex++;
    }

    if (offers.isEmpty) {
      return List<_HomeOfferData>.from(_fallbackSpecialOffers);
    }

    return offers.take(2).toList();
  }

  String _normalizeCategoryLabel(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'burgers':
      case 'burger':
      case 'burrket':
        return 'Burger';
      case 'pizza':
      case 'pizzas':
        return 'Pizza';
      case 'dessert':
      case 'desserts':
        return 'Desserts';
      case 'sushi':
        return 'Sushi';
      case 'noodle':
      case 'noodles':
        return 'Noodles';
      default:
        return _titleCase(value.trim());
    }
  }

  IconData _iconForCategory(String label) {
    switch (label.toLowerCase()) {
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'burger':
      case 'burgers':
        return Icons.lunch_dining_rounded;
      case 'sushi':
        return Icons.set_meal_rounded;
      case 'desserts':
        return Icons.icecream_rounded;
      case 'noodles':
        return Icons.ramen_dining;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  IconData _iconForPromotion(String key, {required IconData fallback}) {
    switch (key.trim().toLowerCase()) {
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'sell':
      case 'tag':
        return Icons.sell_rounded;
      case 'delivery':
      case 'delivery_dining':
        return Icons.delivery_dining_rounded;
      default:
        return fallback;
    }
  }

  String get _userInitials {
    final parts = (_currentUser?.fullName ?? 'Wagba User')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return parts.first.substring(0, 1).toUpperCase();
  }

  void _openSearchTab({bool clearFilters = false}) {
    setState(() {
      if (clearFilters) {
        _searchController.clear();
        _selectedCategory = 'All';
        _searchQuery = '';
      }
      _selectedBottomIndex = 1;
    });
  }

  Future<void> _handleProfileAction(String title) async {
    if (title != 'Profile Info') {
      _showProfileMessage('$title is ready for the next step.');
      return;
    }

    final user = _currentUser;
    if (user == null || user.id == null) {
      _showProfileMessage('Sign in again to update your profile details.');
      return;
    }

    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => ProfileInfoPage(user: user)),
    );

    if (!mounted || updatedUser == null) {
      return;
    }

    setState(() => _currentUser = updatedUser);
    _showProfileMessage('Profile updated successfully.');
  }

  void _showProfileMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C3442),
      ),
    );
  }

  void _handleSignOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildCurrentTab(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedBottomIndex) {
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return CustomerProfileTab(
          user: _currentUser,
          onActionSelected: (title) {
            _handleProfileAction(title);
          },
          onSignOut: _handleSignOut,
        );
      case 0:
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      key: const ValueKey('home-tab'),
      onRefresh: _refreshProducts,
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          _buildHomeHeader(),
          const SizedBox(height: 24),
          _buildSearchAndFilterRow(onFilterTap: () => _openSearchTab()),
          const SizedBox(height: 30),
          _buildSectionHeader(
            title: 'Categories',
            actionLabel: 'View All',
            onTap: () => _openSearchTab(clearFilters: true),
          ),
          const SizedBox(height: 18),
          _buildCategoryRow(),
          const SizedBox(height: 30),
          _buildPromoBanner(),
          const SizedBox(height: 32),
          _buildRestaurantSection(
            title: 'Popular Restaurants',
            actionLabel: 'See All',
            onTap: () => _openSearchTab(),
            previewLimit: 2,
          ),
          const SizedBox(height: 32),
          _buildSpecialOffersSection(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return RefreshIndicator(
      key: const ValueKey('search-tab'),
      onRefresh: _refreshProducts,
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          _buildPageIntro(
            eyebrow: 'SEARCH',
            title: 'Featured Restaurants',
            subtitle:
                'Browse every featured restaurant and filter by category.',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 24),
          _buildSearchAndFilterRow(onFilterTap: _resetFilters),
          const SizedBox(height: 24),
          _buildCategoryRow(),
          const SizedBox(height: 30),
          _buildRestaurantSection(
            title: 'Featured Restaurants',
            actionLabel: 'Refresh',
            onTap: () {
              _refreshProducts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      key: const ValueKey('orders-tab'),
      onRefresh: _refreshCustomerOrders,
      color: AppTheme.primaryColor,
      child: FutureBuilder<List<CustomerOrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <CustomerOrderModel>[];
          final activeOrders = orders.where((order) => order.isActive).toList();
          final pastOrders = orders.where((order) => !order.isActive).toList();
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _buildPageIntro(
                eyebrow: 'ORDERS',
                title: 'Your Orders',
                subtitle: 'Track active deliveries and revisit recent meals.',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildCountCard(
                      value: activeOrders.length.toString(),
                      label: 'Active',
                      icon: Icons.delivery_dining_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildCountCard(
                      value: pastOrders.length.toString(),
                      label: 'Delivered',
                      icon: Icons.check_circle_rounded,
                      tint: const Color(0xFF22A06B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Active Orders',
                actionLabel: 'Refresh',
                onTap: () {
                  _refreshCustomerOrders();
                },
              ),
              const SizedBox(height: 16),
              if (isLoading)
                _buildStatusCard(
                  icon: Icons.autorenew_rounded,
                  message: 'Loading your latest orders...',
                )
              else if (snapshot.hasError)
                _buildStatusCard(
                  icon: Icons.wifi_off_rounded,
                  message:
                      'We could not load your orders right now. Pull to refresh and try again.',
                )
              else if (activeOrders.isEmpty)
                _buildStatusCard(
                  icon: Icons.receipt_long_rounded,
                  message: 'You do not have active orders right now.',
                )
              else ...[
                for (var index = 0; index < activeOrders.length; index++) ...[
                  _buildOrderCard(activeOrders[index]),
                  if (index != activeOrders.length - 1)
                    const SizedBox(height: 16),
                ],
              ],
              const SizedBox(height: 28),
              _buildSectionHeader(
                title: 'Order History',
                actionLabel: 'Refresh',
                onTap: () {
                  _refreshCustomerOrders();
                },
              ),
              const SizedBox(height: 16),
              if (!isLoading && !snapshot.hasError && pastOrders.isEmpty)
                _buildStatusCard(
                  icon: Icons.history_rounded,
                  message: 'Completed orders will appear here after delivery.',
                )
              else if (!isLoading && !snapshot.hasError) ...[
                for (var index = 0; index < pastOrders.length; index++) ...[
                  _buildOrderCard(pastOrders[index]),
                  if (index != pastOrders.length - 1)
                    const SizedBox(height: 16),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIntro({
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 22,
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
              color: const Color(0xFFFFE8DD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFF697894),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7283A1),
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

  Widget _buildCountCard({
    required String value,
    required String label,
    required IconData icon,
    Color tint = AppTheme.primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7283A1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DELIVER TO',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF8C9AB0),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedBottomIndex = 3),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7D3C2), Color(0xFFEAB596)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFFFE9DD), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF172B4D).withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow({required VoidCallback onFilterTap}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172B4D).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 16),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF97A6BD),
                  size: 28,
                ),
                hintText: 'Search food, restaurants...',
                hintStyle: TextStyle(
                  color: Color(0xFF97A6BD),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.label == _selectedCategory;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _selectCategory(category.label),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.24)
                            : const Color(0xFF172B4D).withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    category.icon,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  category.label,
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _promoBanner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _promoBanner.subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                _PromoButton(label: _promoBanner.ctaLabel),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFCC5626).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              Icon(_promoBanner.icon, color: const Color(0xFFCC5626), size: 72),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantSection({
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
    int? previewLimit,
  }) {
    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return _buildStatusCard(
            icon: Icons.cloud_off_rounded,
            message: 'We could not load restaurants right now.',
          );
        }

        final restaurants = _resolveRestaurantCards(snapshot.data ?? const []);
        final visibleRestaurants = previewLimit == null
            ? restaurants
            : restaurants.take(previewLimit).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: title,
              actionLabel: actionLabel,
              onTap: onTap,
            ),
            const SizedBox(height: 18),
            if (restaurants.isEmpty)
              _buildStatusCard(
                icon: Icons.search_off_rounded,
                message: 'No restaurants match your search yet.',
              )
            else
              for (
                var index = 0;
                index < visibleRestaurants.length;
                index++
              ) ...[
                _buildRestaurantCard(visibleRestaurants[index]),
                if (index != visibleRestaurants.length - 1)
                  const SizedBox(height: 28),
              ],
          ],
        );
      },
    );
  }

  Widget _buildSpecialOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Offers',
          style: TextStyle(
            color: AppTheme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (var index = 0; index < _specialOffers.length; index++) ...[
              Expanded(child: _buildOfferCard(_specialOffers[index])),
              if (index != _specialOffers.length - 1) const SizedBox(width: 16),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOfferCard(_HomeOfferData offer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: offer.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: offer.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(offer.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7283A1),
                    fontSize: 13,
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

  Widget _buildStatusCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9AA8BF), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<_RestaurantCardData> _resolveRestaurantCards(
    List<ProductModel> products,
  ) {
    final normalizedQuery = _searchQuery.toLowerCase();

    final filteredProducts = products.where((product) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          _productMatchesQuery(product, normalizedQuery);
      final matchesCategory =
          _selectedCategory == 'All' ||
          _productMatchesCategory(product, _selectedCategory);
      return matchesQuery && matchesCategory;
    }).toList();

    if (filteredProducts.isNotEmpty) {
      return filteredProducts.map(_mapProductToRestaurantCard).toList();
    }

    return _fallbackRestaurants.where((restaurant) {
      final searchableText = '${restaurant.title} ${restaurant.subtitle}'
          .toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory =
          _selectedCategory == 'All' ||
          _restaurantMatchesCategory(searchableText, _selectedCategory);
      return matchesQuery && matchesCategory;
    }).toList();
  }

  bool _productMatchesQuery(ProductModel product, String normalizedQuery) {
    final haystack = [
      product.name,
      product.description,
      product.category,
      product.deliveryTime,
    ].join(' ').toLowerCase();

    return haystack.contains(normalizedQuery);
  }

  bool _productMatchesCategory(ProductModel product, String category) {
    final haystack = [
      product.category,
      product.name,
      product.description,
    ].join(' ').toLowerCase();

    return _restaurantMatchesCategory(haystack, category);
  }

  bool _restaurantMatchesCategory(String haystack, String category) {
    final keywords = _categoryKeywords(category);
    return keywords.any(haystack.contains);
  }

  List<String> _categoryKeywords(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return ['pizza', 'italian', 'pasta'];
      case 'burger':
      case 'burgers':
        return ['burger', 'burgers', 'fries', 'american', 'sandwich'];
      case 'sushi':
        return ['sushi', 'japanese', 'ramen', 'roll'];
      case 'desserts':
        return ['dessert', 'desserts', 'cake', 'ice cream', 'bakery', 'sweet'];
      case 'noodles':
        return ['noodle', 'noodles', 'ramen', 'udon', 'pasta', 'asian'];
      default:
        return [category.toLowerCase()];
    }
  }

  _RestaurantCardData _mapProductToRestaurantCard(ProductModel product) {
    final badges = <String>[];
    if (product.deliveryFee <= 0) {
      badges.add('FREE DELIVERY');
    }
    if (product.rating >= 4.7) {
      badges.add('TOP RATED');
    } else if (product.isAvailable) {
      badges.add('OPEN NOW');
    }
    if (badges.isEmpty) {
      badges.add('PROMO AVAILABLE');
    }

    return _RestaurantCardData(
      title: product.name,
      subtitle:
          '${_cuisineLabel(product.category)} \u2022 ${_primaryDishLabel(product.category)} \u2022 ${_secondaryDishLabel(product.category)}',
      rating: product.rating,
      deliveryTime: product.deliveryTime,
      distanceLabel: _distanceLabel(product),
      priceLabel: _priceLabel(product.price),
      badges: badges,
      product: product,
    );
  }

  String _cuisineLabel(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return 'Italian';
      case 'burger':
      case 'burgers':
      case 'burrket':
        return 'American';
      case 'sushi':
        return 'Japanese';
      case 'desserts':
      case 'bakery':
        return 'Sweet Shop';
      case 'salads':
        return 'Healthy';
      case 'drinks':
        return 'Cafe';
      default:
        return 'Popular';
    }
  }

  String _primaryDishLabel(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return 'Pizza';
      case 'burger':
      case 'burgers':
      case 'burrket':
        return 'Burgers';
      case 'sushi':
        return 'Sushi';
      case 'desserts':
      case 'bakery':
        return 'Desserts';
      case 'noodles':
        return 'Noodles';
      case 'salads':
        return 'Salads';
      case 'drinks':
        return 'Drinks';
      default:
        return _titleCase(category.isEmpty ? 'Food' : category);
    }
  }

  String _secondaryDishLabel(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return 'Pasta';
      case 'burger':
      case 'burgers':
      case 'burrket':
        return 'Fast Food';
      case 'sushi':
        return 'Ramen';
      case 'desserts':
      case 'bakery':
        return 'Treats';
      case 'noodles':
        return 'Broth Bowls';
      case 'salads':
        return 'Bowls';
      case 'drinks':
        return 'Cold Drinks';
      default:
        return 'Chef Picks';
    }
  }

  String _distanceLabel(ProductModel product) {
    final distance = 1.0 + ((product.id * 7) % 24) / 10;
    return '${distance.toStringAsFixed(1)} km';
  }

  String _priceLabel(double price) {
    final isWholeNumber = price == price.truncateToDouble();
    return isWholeNumber
        ? '\$${price.toStringAsFixed(0)}'
        : '\$${price.toStringAsFixed(2)}';
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

  Widget _buildRestaurantCard(_RestaurantCardData restaurant) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 208,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildRestaurantImage(restaurant)),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _buildRatingPill(restaurant.rating),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.title,
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      restaurant.priceLabel,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  restaurant.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7283A1),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaInfo(
                        icon: Icons.access_time_filled_rounded,
                        label: restaurant.deliveryTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetaInfo(
                        icon: Icons.near_me_rounded,
                        label: restaurant.distanceLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final badge in restaurant.badges.take(2))
                      _buildRestaurantFlag(badge),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (restaurant.product == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailsPage(
              restaurant: restaurant.product!,
              user: _currentUser,
              deliveryAddress: _deliveryAddress,
            ),
          ),
        );
      },
      child: card,
    );
  }

  Widget _buildOrderCard(CustomerOrderModel order) {
    final visual = _orderVisualState(order);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: visual.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(visual.icon, color: visual.accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7283A1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildOrderStatusPill(order),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1ECE7)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetaInfo(
                  icon: Icons.access_time_filled_rounded,
                  label: order.timeLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaInfo(
                  icon: Icons.payments_outlined,
                  label: order.totalLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openOrderStatus(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: visual.accent,
                side: BorderSide(color: visual.accent.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                order.isActive ? 'Track Order' : 'View Details',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusPill(CustomerOrderModel order) {
    final visual = _orderVisualState(order);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: visual.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: visual.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  _OrderVisualState _orderVisualState(CustomerOrderModel order) {
    switch (order.stage) {
      case CustomerOrderStage.placed:
        return const _OrderVisualState(
          icon: Icons.receipt_long_rounded,
          accent: AppTheme.primaryColor,
        );
      case CustomerOrderStage.preparing:
        return const _OrderVisualState(
          icon: Icons.restaurant_menu_rounded,
          accent: AppTheme.primaryColor,
        );
      case CustomerOrderStage.onTheWay:
        return const _OrderVisualState(
          icon: Icons.delivery_dining_rounded,
          accent: Color(0xFFFF8A00),
        );
      case CustomerOrderStage.delivered:
        return const _OrderVisualState(
          icon: Icons.check_circle_rounded,
          accent: Color(0xFF22A06B),
        );
      case CustomerOrderStage.cancelled:
        return const _OrderVisualState(
          icon: Icons.cancel_rounded,
          accent: Color(0xFFCC4B4B),
        );
    }
  }

  Future<void> _openOrderStatus(CustomerOrderModel order) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusPage(
          order: order,
          primaryButtonLabel: order.isActive
              ? 'Refresh Status'
              : 'Back to Orders',
          secondaryButtonLabel: 'Back to Home',
          onPrimaryAction: (pageContext) async {
            Navigator.of(pageContext).pop();
            await _refreshCustomerOrders();
          },
          onSecondaryAction: (pageContext) async {
            Navigator.of(pageContext).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  Widget _buildRestaurantFlag(String label) {
    final isNeutral = label.contains('FREE') || label.contains('TOP');
    final backgroundColor = isNeutral
        ? const Color(0xFFF3F5F9)
        : const Color(0xFFFFF0E8);
    final textColor = isNeutral
        ? const Color(0xFF60708E)
        : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildRatingPill(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF4B400), size: 18),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF97A6BD)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8391A7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantImage(_RestaurantCardData restaurant) {
    if (restaurant.product != null) {
      final product = restaurant.product!;
      final imageUrl = product.imageUrl.trim();

      if (imageUrl.isEmpty) {
        return _buildImageFallback(Icons.fastfood_rounded);
      }

      if (imageUrl.startsWith('uploads/')) {
        return Image.network(
          '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildImageFallback(Icons.broken_image_rounded),
        );
      }

      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _buildImageFallback(Icons.broken_image_rounded),
      );
    }

    return Image.asset(
      restaurant.assetPath!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageFallback(Icons.fastfood_rounded),
    );
  }

  Widget _buildImageFallback(IconData icon) {
    return Container(
      color: const Color(0xFFF5EFE8),
      child: Center(child: Icon(icon, color: AppTheme.primaryColor, size: 48)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF0EAE4))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', 0),
          _buildNavItem(Icons.search_rounded, 'Search', 1),
          _buildNavItem(Icons.receipt_long_rounded, 'Orders', 2),
          _buildNavItem(Icons.person_rounded, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedBottomIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF0E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFF6D7B91),
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF6D7B91),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChipData {
  final String label;
  final IconData icon;

  const _CategoryChipData({required this.label, required this.icon});
}

class _HomeOfferData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;

  const _HomeOfferData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
  });
}

class _HomeBannerData {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;

  const _HomeBannerData({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.icon,
  });
}

class _RestaurantCardData {
  final String title;
  final String subtitle;
  final double rating;
  final String deliveryTime;
  final String distanceLabel;
  final String priceLabel;
  final List<String> badges;
  final String? assetPath;
  final ProductModel? product;

  const _RestaurantCardData({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.deliveryTime,
    required this.distanceLabel,
    required this.priceLabel,
    required this.badges,
    this.assetPath,
    this.product,
  });
}

class _PromoButton extends StatelessWidget {
  const _PromoButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _OrderVisualState {
  final IconData icon;
  final Color accent;

  const _OrderVisualState({required this.icon, required this.accent});
}
