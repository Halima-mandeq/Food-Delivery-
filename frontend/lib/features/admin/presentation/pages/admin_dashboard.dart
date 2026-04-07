import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/features/admin/data/services/admin_order_service.dart';
import 'package:food_delivery_frontend/features/admin/data/services/admin_report_service.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/admin/data/services/admin_restaurant_service.dart';
import 'package:food_delivery_frontend/features/admin/data/services/admin_user_service.dart';
import 'package:food_delivery_frontend/features/admin/presentation/pages/add_product_page.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:food_delivery_frontend/features/home/data/models/product_model.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/restaurant_details_page.dart';
import 'package:http/http.dart' as http;

enum RestaurantViewFilter { all, active, inactive, topRated }

enum AdminMobileTab { overview, users, products, orders, reports }

enum AdminUserFilter { all, active, suspended, delivery, admins }

enum AdminOrderFilter { all, pending, preparing, outForDelivery }

extension RestaurantViewFilterX on RestaurantViewFilter {
  String get label {
    switch (this) {
      case RestaurantViewFilter.all:
        return 'All Products';
      case RestaurantViewFilter.active:
        return 'Available';
      case RestaurantViewFilter.inactive:
        return 'Unavailable';
      case RestaurantViewFilter.topRated:
        return 'Top Rated';
    }
  }
}

extension AdminMobileTabX on AdminMobileTab {
  String get label {
    switch (this) {
      case AdminMobileTab.overview:
        return 'Overview';
      case AdminMobileTab.users:
        return 'Users';
      case AdminMobileTab.products:
        return 'Products';
      case AdminMobileTab.orders:
        return 'Orders';
      case AdminMobileTab.reports:
        return 'Reports';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminMobileTab.overview:
        return Icons.grid_view_rounded;
      case AdminMobileTab.users:
        return Icons.group_rounded;
      case AdminMobileTab.products:
        return Icons.inventory_2_rounded;
      case AdminMobileTab.orders:
        return Icons.shopping_cart_rounded;
      case AdminMobileTab.reports:
        return Icons.bar_chart_rounded;
    }
  }
}

extension AdminUserFilterX on AdminUserFilter {
  String get label {
    switch (this) {
      case AdminUserFilter.all:
        return 'All Users';
      case AdminUserFilter.active:
        return 'Active';
      case AdminUserFilter.suspended:
        return 'Suspended';
      case AdminUserFilter.delivery:
        return 'Delivery Partners';
      case AdminUserFilter.admins:
        return 'Admins';
    }
  }
}

extension AdminOrderFilterX on AdminOrderFilter {
  String get label {
    switch (this) {
      case AdminOrderFilter.all:
        return 'All';
      case AdminOrderFilter.pending:
        return 'Pending';
      case AdminOrderFilter.preparing:
        return 'Preparing';
      case AdminOrderFilter.outForDelivery:
        return 'Out for Delivery';
    }
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Map<String, dynamic> _fallbackStats = <String, dynamic>{
    'revenue': '0.00',
    'orders': '0',
    'activeOrders': '0',
    'deliveries': '0',
    'newUsers': '0',
    'totalProducts': '0',
    'rating': '0.0',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AdminOrderService _orderService = AdminOrderService();
  final AdminReportService _reportService = AdminReportService();
  final AdminRestaurantService _restaurantService = AdminRestaurantService();
  final AdminUserService _userService = AdminUserService();
  final TextEditingController _orderSearchController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  Map<String, dynamic> _stats = Map<String, dynamic>.from(_fallbackStats);
  List<Map<String, dynamic>> _recentOrders = [];
  List<AdminOrderRecord> _orders = [];
  AdminReportsData _reportsData = const AdminReportsData.empty();
  List<AdminRestaurantRecord> _restaurants = [];
  List<AdminUserRecord> _users = [];
  bool _isLoading = true;
  String? _loadError;
  AdminOrderFilter _selectedOrderFilter = AdminOrderFilter.all;
  RestaurantViewFilter _selectedFilter = RestaurantViewFilter.all;
  AdminMobileTab _selectedMobileTab = AdminMobileTab.overview;
  AdminUserFilter _selectedUserFilter = AdminUserFilter.active;
  final Map<int, AdminUserStatus> _userStatusOverrides =
      <int, AdminUserStatus>{};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _orderSearchController.addListener(_refreshOrderSearch);
    _searchController.addListener(_resetPagination);
    _userSearchController.addListener(_refreshUserSearch);
    _loadData();
  }

  @override
  void dispose() {
    _orderSearchController.removeListener(_refreshOrderSearch);
    _searchController.removeListener(_resetPagination);
    _userSearchController.removeListener(_refreshUserSearch);
    _orderSearchController.dispose();
    _searchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    setState(() => _currentPage = 0);
  }

  void _refreshUserSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshOrderSearch() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _orderService.getOrders(),
        _restaurantService.getRestaurants(),
        _userService.getUsers(),
        _fetchDashboardData(),
        _reportService.getReports(),
      ]);
      final orders = results[0] as List<AdminOrderRecord>;
      final restaurants = results[1] as List<AdminRestaurantRecord>;
      final users = results[2] as List<AdminUserRecord>;
      final dashboardData = results[3] as Map<String, dynamic>;
      final reportsData = results[4] as AdminReportsData;
      final stats = Map<String, dynamic>.from(dashboardData['stats'] as Map);
      final recentOrders = List<Map<String, dynamic>>.from(
        dashboardData['recentOrders'] as List,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _restaurants = restaurants;
        _users = users;
        _stats = stats;
        _recentOrders = recentOrders;
        _reportsData = reportsData;
        _isLoading = false;
        _loadError = null;
        _currentPage = 0;
      });
    } catch (e) {
      debugPrint('Error loading admin dashboard: $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Could not refresh the admin dashboard.';
        _orders = [];
        _recentOrders = [];
        _reportsData = const AdminReportsData.empty();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/get_admin_stats.php'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch admin stats');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Invalid admin stats response');
    }

    final stats = decoded['stats'];
    final recentOrders = decoded['recentOrders'];
    return <String, dynamic>{
      'stats': stats is Map
          ? Map<String, dynamic>.from(stats)
          : Map<String, dynamic>.from(_fallbackStats),
      'recentOrders': recentOrders is List
          ? recentOrders
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList()
          : <Map<String, dynamic>>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1080;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F3F0),
      drawer: isDesktop ? null : _buildMobileDrawer(),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNavigationBar(),
      floatingActionButton:
          !isDesktop && _selectedMobileTab == AdminMobileTab.users
          ? FloatingActionButton(
              onPressed: _showAddUserDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 34),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  SizedBox(width: 320, child: _buildSidebar()),
                  Expanded(child: _buildBody(context, isDesktop: isDesktop)),
                ],
              )
            : _buildBody(context, isDesktop: isDesktop),
      ),
    );
  }

  Widget _buildSidebar() {
    final items = const <Map<String, dynamic>>[
      {'label': 'Dashboard', 'icon': Icons.dashboard_rounded, 'active': false},
      {'label': 'Products', 'icon': Icons.storefront_rounded, 'active': true},
      {'label': 'Orders', 'icon': Icons.receipt_long_rounded, 'active': false},
      {'label': 'Customers', 'icon': Icons.group_rounded, 'active': false},
      {'label': 'Analytics', 'icon': Icons.bar_chart_rounded, 'active': false},
      {'label': 'Settings', 'icon': Icons.settings_rounded, 'active': false},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.flatware_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Portal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'MANAGEMENT SYSTEM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          for (final item in items) ...[
            _buildSidebarItem(
              label: item['label'] as String,
              icon: item['icon'] as IconData,
              active: item['active'] as bool,
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          Container(height: 1, color: const Color(0xFFE7ECF3)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String label,
    required IconData icon,
    required bool active,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF0E8) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? AppTheme.primaryColor : const Color(0xFF64748B),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isDesktop}) {
    if (_isLoading &&
        _restaurants.isEmpty &&
        _users.isEmpty &&
        _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    final filtered = _filteredRestaurants;
    final pageSize = isDesktop ? 4 : 5;
    final totalPages = filtered.isEmpty
        ? 1
        : ((filtered.length - 1) / pageSize).floor() + 1;
    final currentPage = math.min(math.max(_currentPage, 0), totalPages - 1);
    final pageItems = filtered
        .skip(currentPage * pageSize)
        .take(pageSize)
        .toList();
    final start = filtered.isEmpty ? 0 : currentPage * pageSize + 1;
    final end = filtered.isEmpty
        ? 0
        : math.min(filtered.length, (currentPage + 1) * pageSize);

    if (!isDesktop) {
      return _buildMobileBody(
        filtered: filtered,
        pageItems: pageItems,
        start: start,
        end: end,
        total: filtered.length,
        totalPages: totalPages,
        currentPage: currentPage,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 40 : 20,
          isDesktop ? 28 : 20,
          isDesktop ? 40 : 20,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadError != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 20),
            ],
            _buildHeader(isDesktop: isDesktop),
            const SizedBox(height: 22),
            _buildSummaryCards(isDesktop: isDesktop),
            const SizedBox(height: 24),
            _buildSearchAndFilters(isDesktop: isDesktop),
            const SizedBox(height: 24),
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              _buildRestaurantTable(
                pageItems: pageItems,
                start: start,
                end: end,
                total: filtered.length,
                totalPages: totalPages,
                currentPage: currentPage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBody({
    required List<AdminRestaurantRecord> filtered,
    required List<AdminRestaurantRecord> pageItems,
    required int start,
    required int end,
    required int total,
    required int totalPages,
    required int currentPage,
  }) {
    Widget content;

    switch (_selectedMobileTab) {
      case AdminMobileTab.overview:
        content = _buildMobileOverviewContent();
        break;
      case AdminMobileTab.users:
        content = _buildMobileUsersContent();
        break;
      case AdminMobileTab.products:
        content = _buildMobileProductsContent(
          filtered: filtered,
          pageItems: pageItems,
          start: start,
          end: end,
          total: total,
          totalPages: totalPages,
          currentPage: currentPage,
        );
        break;
      case AdminMobileTab.orders:
        content = _buildMobileOrdersContent();
        break;
      case AdminMobileTab.reports:
        content = _buildMobileReportsContent();
        break;
    }

    return Column(
      children: [
        _buildMobileAppBar(),
        Container(height: 1, color: const Color(0xFFE8E1DA)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadData(showLoading: false),
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadError != null) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 20),
                  ],
                  content,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAppBar() {
    if (_selectedMobileTab == AdminMobileTab.reports) {
      return _buildReportsMobileAppBar();
    }

    String title;
    switch (_selectedMobileTab) {
      case AdminMobileTab.overview:
        title = 'Admin Dashboard';
        break;
      case AdminMobileTab.users:
        title = 'User Management';
        break;
      case AdminMobileTab.products:
        title = 'Product Management';
        break;
      case AdminMobileTab.orders:
        title = 'Orders';
        break;
      case AdminMobileTab.reports:
        title = 'Reports';
        break;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.accentColor,
                size: 30,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _selectedMobileTab == AdminMobileTab.orders
                      ? 21
                      : 20,
                  fontWeight: FontWeight.w900,
                  color: _selectedMobileTab == AdminMobileTab.orders
                      ? const Color(0xFF171212)
                      : AppTheme.primaryColor,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: AppTheme.accentColor,
                    size: 28,
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsMobileAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF122033), Color(0xFF223A58)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFFFD6C3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'SAFFRON HORIZON',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFF283C59),
                    size: 27,
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Overview and operations',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9EEF5)),
            const SizedBox(height: 12),
            for (final tab in AdminMobileTab.values) ...[
              _buildDrawerItem(tab),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(AdminMobileTab tab) {
    final isSelected = _selectedMobileTab == tab;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        onTap: () {
          Navigator.of(context).pop();
          setState(() => _selectedMobileTab = tab);
        },
        leading: Icon(
          tab.icon,
          color: isSelected ? AppTheme.primaryColor : const Color(0xFF94A3B8),
        ),
        title: Text(
          tab.label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isSelected ? AppTheme.primaryColor : AppTheme.accentColor,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: isSelected ? const Color(0xFFFFF3EA) : Colors.transparent,
      ),
    );
  }

  Widget _buildMobileBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final tab in AdminMobileTab.values)
              Expanded(child: _buildBottomNavItem(tab)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(AdminMobileTab tab) {
    final isSelected = _selectedMobileTab == tab;
    final activeColor = const Color(0xFFFF7A45);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _selectedMobileTab = tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFF1EA)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tab.icon,
                color: isSelected ? activeColor : const Color(0xFF7C8BA1),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tab.label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isSelected ? activeColor : const Color(0xFF7C8BA1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOverviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewMetricsGrid(),
        const SizedBox(height: 28),
        _buildRevenueOverviewCard(),
        const SizedBox(height: 30),
        _buildSectionHeading(
          title: 'Recent Orders',
          actionLabel: 'View All',
          onTap: () =>
              setState(() => _selectedMobileTab = AdminMobileTab.orders),
        ),
        const SizedBox(height: 16),
        _buildRecentOrderList(limit: 4),
      ],
    );
  }

  Widget _buildMobileUsersContent() {
    final totalUsers = _formatCount(_customerUsers.length);
    final newUsers = _formatCount(_newCustomerCountLast24Hours);
    final visibleUsers = _filteredAdminUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildUserSummaryCard(
                title: 'Total Users',
                value: totalUsers,
                subtitle: _customerGrowthLabel,
                icon: Icons.group_rounded,
                accent: const Color(0xFF12B76A),
                subtitleColor: const Color(0xFF12B76A),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserSummaryCard(
                title: 'New Signups',
                value: newUsers,
                subtitle: 'Last 24 Hours',
                icon: Icons.person_add_alt_1_rounded,
                accent: AppTheme.primaryColor,
                highlighted: true,
                subtitleColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildUserSearchField(),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                _userSectionTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF63799A),
                  letterSpacing: 1.3,
                ),
              ),
            ),
            _buildUserFilterButton(),
          ],
        ),
        const SizedBox(height: 16),
        if (visibleUsers.isEmpty)
          _buildUsersEmptyState()
        else
          Column(
            children: [
              for (int index = 0; index < visibleUsers.length; index++) ...[
                _buildUserCard(visibleUsers[index]),
                if (index != visibleUsers.length - 1)
                  const SizedBox(height: 18),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildUserSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color subtitleColor,
    bool highlighted = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF0E9) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: highlighted
            ? Border.all(color: const Color(0xFFFFD2BE))
            : Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: highlighted ? 0.1 : 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 32),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: highlighted
                  ? AppTheme.primaryColor
                  : const Color(0xFF63799A),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: highlighted
                  ? AppTheme.primaryColor
                  : const Color(0xFF171212),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSearchField() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 38, color: Color(0xFF94A3B8)),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_userSearchController.text.isNotEmpty)
            IconButton(
              onPressed: () => _userSearchController.clear(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildUserFilterButton() {
    return PopupMenuButton<AdminUserFilter>(
      initialValue: _selectedUserFilter,
      onSelected: (filter) => setState(() => _selectedUserFilter = filter),
      color: Colors.white,
      itemBuilder: (context) => AdminUserFilter.values
          .map(
            (filter) => PopupMenuItem<AdminUserFilter>(
              value: filter,
              child: Text(
                filter.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
      child: Row(
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.tune_rounded,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.group_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No users match this filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search or filter to see more users.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUserRecord user) {
    final status = _effectiveUserStatus(user);
    final isSuspended = status == AdminUserStatus.suspended;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserAvatar(user),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF171212),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildUserRoleBadge(user.role),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSuspended
                        ? const Color(0xFFFFE7E7)
                        : const Color(0xFFDFF9EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSuspended ? 'SUSPENDED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSuspended
                          ? const Color(0xFFFF5B5B)
                          : const Color(0xFF0E9F6E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      _buildUserInfoStat(
                        label: 'Orders',
                        value: user.totalOrders.toString().padLeft(2, '0'),
                      ),
                      _buildUserInfoStat(
                        label: 'Joined',
                        value: _formatUserJoined(user.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _buildUserActionButton(
                      icon: Icons.edit_rounded,
                      onTap: () => _showEditUserMessage(user),
                    ),
                    const SizedBox(width: 10),
                    isSuspended
                        ? GestureDetector(
                            onTap: () => _toggleUserStatus(user),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'ACTIVATE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : _buildUserActionButton(
                            icon: Icons.block_rounded,
                            iconColor: const Color(0xFFFF5B5B),
                            onTap: () => _toggleUserStatus(user),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AdminUserRecord user) {
    final palette = _avatarPaletteForUser(user);
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF171212),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRoleBadge(String role) {
    late final String label;
    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (role.toLowerCase()) {
      case 'admin':
        label = 'ADMIN';
        backgroundColor = const Color(0xFFE8EDFF);
        foregroundColor = const Color(0xFF3B5BDB);
        break;
      case 'delivery':
        label = 'DELIVERY';
        backgroundColor = const Color(0xFFFFF1E8);
        foregroundColor = AppTheme.primaryColor;
        break;
      default:
        label = 'USER';
        backgroundColor = const Color(0xFFE9FAF0);
        foregroundColor = const Color(0xFF0E9F6E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF64748B),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6ECF2)),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _buildMobileOrdersContent() {
    final activeOrders = _formatCount(
      _orders
          .where(
            (order) =>
                order.status.toLowerCase() != 'completed' &&
                order.status.toLowerCase() != 'cancelled',
          )
          .length,
    );
    final deliveredToday = _formatCount(
      _orders
          .where((order) => order.status.toLowerCase() == 'completed')
          .length,
    );
    final visibleOrders = _filteredAdminOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildOrderSummaryCard(
                value: activeOrders,
                label: 'Live Orders',
                badge: 'ACTIVE',
                icon: Icons.av_timer_rounded,
                accent: AppTheme.primaryColor,
                iconBackground: const Color(0xFFFFF2E9),
                badgeBackground: const Color(0xFFFFF1EA),
                badgeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrderSummaryCard(
                value: deliveredToday,
                label: 'Delivered Today',
                badge: 'GROWTH',
                icon: Icons.check_circle_rounded,
                accent: const Color(0xFF12B76A),
                iconBackground: const Color(0xFFDFF9EA),
                badgeBackground: const Color(0xFFE9FAF0),
                badgeColor: const Color(0xFF0E9F6E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildOrderSearchField(),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in AdminOrderFilter.values) ...[
                _buildOrderFilterChip(filter),
                if (filter != AdminOrderFilter.values.last)
                  const SizedBox(width: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (visibleOrders.isEmpty)
          _buildOrdersEmptyState()
        else
          Column(
            children: [
              for (int index = 0; index < visibleOrders.length; index++) ...[
                _buildAdminOrderCard(visibleOrders[index]),
                if (index != visibleOrders.length - 1)
                  const SizedBox(height: 18),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildOrderSummaryCard({
    required String value,
    required String label,
    required String badge,
    required IconData icon,
    required Color accent,
    required Color iconBackground,
    required Color badgeBackground,
    required Color badgeColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 198),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF182234),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF63799A),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSearchField() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 34, color: Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _orderSearchController,
              decoration: const InputDecoration(
                hintText: 'Search ID or customer name...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_orderSearchController.text.isNotEmpty)
            IconButton(
              onPressed: () => _orderSearchController.clear(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderFilterChip(AdminOrderFilter filter) {
    final isSelected = _selectedOrderFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selectedOrderFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_cart_checkout_rounded,
            size: 38,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'No orders match this filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different search or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrderCard(AdminOrderRecord order) {
    final stage = _resolveAdminOrderStage(order);
    final merchant = _merchantForOrder(order);
    final merchantName = merchant?.restaurant.name ?? 'Platform Kitchen';
    final merchantImage = merchant?.restaurant.imageUrl ?? '';
    final timeLabel = _formatOrderTime(order.createdAt?.toIso8601String());
    final orderCode = '#ORD-${order.id.toString().padLeft(4, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderMerchantImage(merchantImage),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderCode,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF171212),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLabel.isEmpty
                            ? merchantName
                            : '$merchantName - $timeLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: stage.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    stage.label,
                    style: TextStyle(
                      color: stage.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF182234),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrencyValue(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildOrderActionButton(
                    label: 'Details',
                    icon: Icons.visibility_rounded,
                    onTap: () => _showOrderDetailsMessage(order),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOrderActionButton(
                    label: 'Status',
                    icon: Icons.swap_horiz_rounded,
                    onTap: () => _showOrderStatusMessage(order, stage),
                    filled: true,
                  ),
                ),
                const SizedBox(width: 12),
                _buildSquareOrderActionButton(
                  icon: Icons.call_rounded,
                  onTap: () => _showOrderContactMessage(order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMerchantImage(String imageUrl) {
    Widget child;
    if (imageUrl.isEmpty) {
      child = const Icon(Icons.fastfood_rounded, color: Colors.grey);
    } else if (imageUrl.startsWith('uploads/')) {
      child = Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.fastfood_rounded, color: Colors.grey),
      );
    } else {
      child = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.fastfood_rounded, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66,
        height: 66,
        color: const Color(0xFFF8FAFC),
        child: child,
      ),
    );
  }

  Widget _buildOrderActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: filled ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : const Color(0xFF334155),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareOrderActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: const Color(0xFF334155)),
      ),
    );
  }

  Widget _buildMobileProductsContent({
    required List<AdminRestaurantRecord> filtered,
    required List<AdminRestaurantRecord> pageItems,
    required int start,
    required int end,
    required int total,
    required int totalPages,
    required int currentPage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(title: 'Products'),
        const SizedBox(height: 18),
        _buildHeader(isDesktop: false),
        const SizedBox(height: 22),
        _buildSearchAndFilters(isDesktop: false),
        const SizedBox(height: 24),
        if (filtered.isEmpty)
          _buildEmptyState()
        else
          _buildRestaurantCards(
            pageItems: pageItems,
            start: start,
            end: end,
            total: total,
            totalPages: totalPages,
            currentPage: currentPage,
          ),
      ],
    );
  }

  Widget _buildMobileReportsContent() {
    final reportSummary = _reportsData.summary;
    final categories = _reportsData.categories;
    final topVendors = _reportsData.vendors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analytics Reports',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF171B34),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Performance summary for the last 30 days',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7C8BA1),
          ),
        ),
        const SizedBox(height: 26),
        _buildReportsHeroCard(reportSummary),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReportsMetricCard(
                title: 'Avg. Order',
                value: _formatCurrencyValue(reportSummary.averageOrder),
                subtitle: reportSummary.totalOrders == 0
                    ? 'No orders yet'
                    : '${_formatCount(reportSummary.totalOrders)} total orders',
                subtitleColor: const Color(0xFF8FA0B7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportsMetricCard(
                title: 'Cust. Growth',
                value: _formatCount(reportSummary.customerCount),
                subtitle: reportSummary.newCustomers == 0
                    ? 'No new users this week'
                    : '+${_formatCount(reportSummary.newCustomers)} new this month',
                subtitleColor: const Color(0xFF12B76A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildReportsTrendCard(_reportsData.weeklyRevenue),
        const SizedBox(height: 32),
        _buildSectionHeading(title: 'Popular Categories'),
        const SizedBox(height: 16),
        _buildReportsCategoriesCard(categories),
        const SizedBox(height: 32),
        _buildSectionHeading(
          title: 'Top Performing Vendors',
          actionLabel: 'View All',
          onTap: () =>
              setState(() => _selectedMobileTab = AdminMobileTab.products),
        ),
        const SizedBox(height: 16),
        _buildReportsTopVendors(topVendors),
      ],
    );
  }

  Widget _buildReportsHeroCard(AdminReportSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL REVENUE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9AA8BE),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrencyValue(summary.totalRevenue),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FBF0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 16,
                  color: Color(0xFF12B76A),
                ),
                const SizedBox(width: 4),
                Text(
                  '${summary.revenueGrowthPercent.toStringAsFixed(summary.revenueGrowthPercent % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12B76A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 146),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9AA8BE),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171212),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTrendCard(List<AdminReportRevenuePoint> weeklyRevenue) {
    final points = weeklyRevenue.isEmpty
        ? const <double>[0, 0, 0, 0, 0, 0, 0]
        : _normalizeReportTrend(weeklyRevenue);
    final labels = weeklyRevenue.isEmpty
        ? const <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
        : weeklyRevenue.map((point) => point.label).toList();
    const colors = <Color>[
      Color(0xFFF0D8CF),
      Color(0xFFF6B9A2),
      Color(0xFFEFD7CF),
      Color(0xFFFF6B2C),
      Color(0xFFF89D79),
      Color(0xFFF6B7A3),
      Color(0xFFFF6B2C),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Revenue Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'WEEKLY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(points.length, (index) {
                final height = 56 + (points[index] * 126);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9AA8BE),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsCategoriesCard(List<AdminReportCategory> categories) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.category_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No categories available yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171212),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Add restaurants to start tracking category performance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7C8BA1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < categories.length; index++) ...[
            _buildReportsCategoryRow(categories[index], index),
            if (index != categories.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsCategoryRow(AdminReportCategory category, int index) {
    const palette = <Color>[
      Color(0xFFFF6B2C),
      Color(0xFFFF9458),
      Color(0xFFB9C5D6),
      Color(0xFFD5DDE8),
    ];
    final color = palette[index % palette.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF24364E),
                ),
              ),
            ),
            Text(
              '${category.percentage}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171212),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (category.percentage.clamp(0, 100) / 100),
            minHeight: 8,
            backgroundColor: const Color(0xFFE9EEF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTopVendors(List<AdminReportVendor> vendors) {
    if (vendors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.storefront_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No vendor performance data yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171212),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Vendor highlights will appear here as restaurants and orders grow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7C8BA1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < vendors.length; index++) ...[
          _buildReportsVendorCard(vendors[index]),
          if (index != vendors.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildReportsVendorCard(AdminReportVendor vendor) {
    final vendorStatus = _reportVendorStatusStyle(vendor.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildReportVendorImage(vendor.imageUrl, width: 64, height: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vendor.metric,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8EA0B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyValue(vendor.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF171212),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vendorStatus.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: vendorStatus.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetricsGrid() {
    final metrics = <_OverviewMetric>[
      _OverviewMetric(
        title: 'Total Revenue',
        value: _formatCurrencyValue(_stats['revenue']),
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFFFF6B2C),
        iconBackground: const Color(0xFFFFF2E8),
        badgeLabel: '+12%',
        badgeBackground: const Color(0xFFE9FAF0),
        badgeColor: const Color(0xFF12B76A),
      ),
      _OverviewMetric(
        title: 'Active Orders',
        value: _formatCount(_safeInt(_stats['activeOrders'])),
        icon: Icons.restaurant_menu_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBackground: const Color(0xFFEAF2FF),
        badgeLabel: 'LIVE',
        badgeBackground: const Color(0xFFFFF3EA),
        badgeColor: const Color(0xFFFF6B2C),
      ),
      _OverviewMetric(
        title: 'Total Products',
        value: _formatCount(_totalProductsCount),
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF0EA5A4),
        iconBackground: const Color(0xFFE6FFFB),
        badgeLabel: '${_productAvailabilityRate}%',
        badgeBackground: const Color(0xFFE8FBF0),
        badgeColor: const Color(0xFF12B76A),
      ),
      _OverviewMetric(
        title: 'New Users',
        value: _formatCount(_safeInt(_stats['newUsers'])),
        icon: Icons.group_rounded,
        iconColor: const Color(0xFFA855F7),
        iconBackground: const Color(0xFFF5EBFF),
        badgeLabel: '+${_formatCount(_safeInt(_stats['newUsers']))}',
        badgeBackground: const Color(0xFFE9FAF0),
        badgeColor: const Color(0xFF12B76A),
      ),
      _OverviewMetric(
        title: 'Deliveries',
        value: _formatCount(_safeInt(_stats['deliveries'])),
        icon: Icons.local_shipping_rounded,
        iconColor: const Color(0xFF12B76A),
        iconBackground: const Color(0xFFE8FFF3),
        badgeLabel: '${_completionRate}%',
        badgeBackground: const Color(0xFFF1F5F9),
        badgeColor: const Color(0xFF94A3B8),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 198,
      ),
      itemBuilder: (context, index) => _buildOverviewMetricCard(metrics[index]),
    );
  }

  Widget _buildOverviewMetricCard(_OverviewMetric metric) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: metric.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(metric.icon, color: metric.iconColor, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: metric.badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  metric.badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: metric.badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7587A5),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171212),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverviewCard() {
    final points = _revenueTrendPoints;
    const labels = <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Revenue Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                label: const Text('WEEKLY'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: CustomPaint(
              painter: _RevenueTrendPainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171212),
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentOrderList({int? limit}) {
    final visibleOrders = limit == null
        ? _recentOrders
        : _recentOrders.take(limit).toList();

    if (visibleOrders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 34,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'No recent orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentColor,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pull to refresh after new orders come in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < visibleOrders.length; index++) ...[
          _buildRecentOrderCard(visibleOrders[index]),
          if (index != visibleOrders.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final status = _resolveOrderStatus(order['status']?.toString() ?? '');
    final createdAt = _formatOrderTime(order['created_at']);
    final orderId = int.tryParse(order['id']?.toString() ?? '') ?? 0;
    final amount = _formatCurrencyValue(order['total_amount']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6ECF2)),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#ORD-${orderId.toString().padLeft(4, '0')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdAt.isEmpty
                      ? 'Latest platform order'
                      : 'Updated $createdAt',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF171212),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: status.textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isDesktop}) {
    final button = ElevatedButton.icon(
      onPressed: _openAddRestaurant,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add New Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.accentColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0xFFE5EAF1)),
        ),
      ),
    );

    if (!isDesktop) {
      return Align(alignment: Alignment.centerLeft, child: button);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accentColor,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Manage your catalog, availability, and product performance.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        button,
      ],
    );
  }

  Widget _buildSummaryCards({required bool isDesktop}) {
    final activeCount = _activeProductCount;
    final isCompact = !isDesktop;
    final cards = [
      _buildSummaryCard(
        'Revenue',
        '\$${_stats['revenue'] ?? '0.00'}',
        Icons.payments_rounded,
        const Color(0xFFFF8A3D),
        isCompact: isCompact,
      ),
      _buildSummaryCard(
        'Orders',
        _stats['orders']?.toString() ?? '0',
        Icons.shopping_bag_rounded,
        const Color(0xFF4F7CFF),
        isCompact: isCompact,
      ),
      _buildSummaryCard(
        'Total Products',
        _formatCount(_totalProductsCount),
        Icons.inventory_2_rounded,
        const Color(0xFF0EA5A4),
        isCompact: isCompact,
      ),
      _buildSummaryCard(
        'Active Products',
        _formatCount(activeCount),
        Icons.check_circle_rounded,
        const Color(0xFF12B76A),
        isCompact: isCompact,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.45 : 1,
        mainAxisExtent: isDesktop ? null : 156,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color accent, {
    bool isCompact = false,
  }) {
    final cardPadding = isCompact ? 18.0 : 20.0;
    final cardRadius = isCompact ? 22.0 : 24.0;
    final iconBoxSize = isCompact ? 40.0 : 44.0;
    final iconRadius = isCompact ? 12.0 : 14.0;
    final valueSpacing = isCompact ? 14.0 : 16.0;
    final valueFontSize = isCompact ? 22.0 : 24.0;
    final titleFontSize = isCompact ? 13.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Icon(icon, color: accent),
          ),
          SizedBox(height: valueSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters({required bool isDesktop}) {
    final filters = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final filter in RestaurantViewFilter.values)
          _buildFilterChip(filter),
      ],
    );

    if (!isDesktop) {
      return Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: filters),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildSearchField()),
        const SizedBox(width: 18),
        Expanded(
          flex: 6,
          child: Align(alignment: Alignment.centerRight, child: filters),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, category, or description...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () => _searchController.clear(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(RestaurantViewFilter filter) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _currentPage = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0E8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD6BE)
                : const Color(0xFFE5EAF1),
          ),
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.primaryColor : AppTheme.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantTable({
    required List<AdminRestaurantRecord> pageItems,
    required int start,
    required int end,
    required int total,
    required int totalPages,
    required int currentPage,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          for (final record in pageItems) _buildTableRow(record),
          _buildFooter(
            start: start,
            end: end,
            total: total,
            totalPages: totalPages,
            currentPage: currentPage,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EEF5))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 5, child: _HeaderText('PRODUCT')),
          Expanded(flex: 3, child: _HeaderText('CATEGORY')),
          Expanded(flex: 3, child: _HeaderText('STATUS')),
          Expanded(flex: 3, child: _HeaderText('RATING')),
          Expanded(flex: 3, child: _HeaderText('TOTAL ORDERS')),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeaderText('ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AdminRestaurantRecord record) {
    final restaurant = record.restaurant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFF3F8))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _buildRestaurantImage(restaurant, width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${_restaurantCode(restaurant)}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: _buildCategoryBadge(restaurant.category)),
          Expanded(flex: 3, child: _buildStatusRow(restaurant.isAvailable)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFDB022),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  restaurant.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatCount(record.totalOrders),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 2,
                children: [
                  _buildActionIcon(
                    Icons.edit_outlined,
                    () => _openAddRestaurant(restaurant: restaurant),
                  ),
                  _buildActionIcon(
                    Icons.visibility_outlined,
                    () => _openPreview(restaurant),
                  ),
                  _buildActionIcon(
                    Icons.delete_outline_rounded,
                    () => _confirmDelete(record),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCards({
    required List<AdminRestaurantRecord> pageItems,
    required int start,
    required int end,
    required int total,
    required int totalPages,
    required int currentPage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final record in pageItems) ...[
            _buildRestaurantCard(record),
            const SizedBox(height: 14),
          ],
          _buildFooter(
            start: start,
            end: end,
            total: total,
            totalPages: totalPages,
            currentPage: currentPage,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(AdminRestaurantRecord record) {
    final restaurant = record.restaurant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRestaurantImage(restaurant, width: 62, height: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _restaurantCode(restaurant),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCategoryBadge(restaurant.category),
              _buildStatusBadge(restaurant.isAvailable),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFDB022)),
              const SizedBox(width: 6),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatCount(record.totalOrders)} orders',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAddRestaurant(restaurant: restaurant),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                    side: const BorderSide(color: Color(0xFFD9E2EC)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openPreview(restaurant),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(record),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete Product'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({
    required int start,
    required int end,
    required int total,
    required int totalPages,
    required int currentPage,
  }) {
    final pages = _visiblePages(totalPages, currentPage);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start to $end of $total products',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          if (total > 0)
            Wrap(
              spacing: 10,
              children: [
                _buildPageCircle(
                  icon: Icons.chevron_left_rounded,
                  enabled: currentPage > 0,
                  onTap: () => setState(() => _currentPage = currentPage - 1),
                ),
                for (final page in pages)
                  _buildPageNumber(page, currentPage == page),
                _buildPageCircle(
                  icon: Icons.chevron_right_rounded,
                  enabled: currentPage < totalPages - 1,
                  onTap: () => setState(() => _currentPage = currentPage + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPageCircle({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Icon(
          icon,
          color: enabled ? AppTheme.accentColor : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int page, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFD9E2EC),
          ),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppTheme.accentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF94A3B8)),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final label = category.trim().isEmpty ? 'General' : category.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildStatusRow(bool isAvailable) {
    final color = isAvailable
        ? const Color(0xFF12B76A)
        : const Color(0xFF94A3B8);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isAvailable ? 'ACTIVE' : 'INACTIVE',
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    final color = isAvailable
        ? const Color(0xFF12B76A)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8FFF3) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isAvailable ? 'Active' : 'Inactive',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantImage(
    ProductModel restaurant, {
    double width = 72,
    double height = 72,
  }) {
    final imageUrl = restaurant.imageUrl.trim();
    Widget child;

    if (imageUrl.isEmpty) {
      child = const Icon(Icons.storefront_rounded, color: Colors.grey);
    } else if (imageUrl.startsWith('uploads/')) {
      child = Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    } else {
      child = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: child,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'No products match your filters',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting the search or filter set to see more products.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD6BE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Some admin data could not be refreshed. Pull down or tap retry to try again.',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadData(),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddRestaurant({ProductModel? restaurant}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductPage(product: restaurant)),
    );

    if (result == true) {
      await _loadData(showLoading: false);
    }
  }

  Future<void> _openPreview(ProductModel restaurant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsPage(restaurant: restaurant),
      ),
    );
  }

  Future<void> _confirmDelete(AdminRestaurantRecord record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          "Delete '${record.restaurant.name}' from the product catalog?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE11D48)),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteRestaurant(record.restaurant.id);
    }
  }

  Future<void> _deleteRestaurant(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/delete_product.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        await _loadData(showLoading: false);
      } else {
        throw Exception(result['error'] ?? 'Failed to delete product');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  int get _completionRate {
    final totalOrders = _safeInt(_stats['orders']);
    final deliveries = _safeInt(_stats['deliveries']);
    if (totalOrders <= 0) {
      return 0;
    }

    return ((deliveries / totalOrders) * 100).round();
  }

  int get _totalProductsCount {
    final statsCount = _safeInt(_stats['totalProducts']);
    if (statsCount > 0 || _restaurants.isEmpty) {
      return statsCount;
    }

    return _restaurants.length;
  }

  int get _activeProductCount =>
      _restaurants.where((record) => record.restaurant.isAvailable).length;

  int get _productAvailabilityRate {
    final totalProducts = _totalProductsCount;
    if (totalProducts <= 0) {
      return 0;
    }

    return ((_activeProductCount / totalProducts) * 100).round();
  }

  List<double> get _revenueTrendPoints {
    const fallback = <double>[0.42, 0.53, 0.47, 0.64, 0.58, 0.77, 0.69];
    final revenue = _safeDouble(_stats['revenue']);
    final totalOrders = _safeInt(_stats['orders']);
    final activeOrders = _safeInt(_stats['activeOrders']);
    final deliveries = _safeInt(_stats['deliveries']);
    final newUsers = _safeInt(_stats['newUsers']);

    if (revenue <= 0 &&
        totalOrders == 0 &&
        activeOrders == 0 &&
        deliveries == 0 &&
        newUsers == 0) {
      return fallback;
    }

    final values = <double>[
      revenue * 0.36 + totalOrders * 2.2,
      revenue * 0.48 + activeOrders * 2.8,
      revenue * 0.43 + deliveries * 2.4,
      revenue * 0.63 + totalOrders * 3.0,
      revenue * 0.57 + newUsers * 1.9,
      revenue * 0.79 + deliveries * 3.3,
      revenue * 0.68 + activeOrders * 2.6,
    ];
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) {
      return fallback;
    }

    return values.map((value) => value / maxValue).toList();
  }

  List<double> _normalizeReportTrend(List<AdminReportRevenuePoint> points) {
    if (points.isEmpty) {
      return const <double>[0, 0, 0, 0, 0, 0, 0];
    }

    final values = points.map((point) => point.amount).toList();
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) {
      return List<double>.filled(points.length, 0);
    }

    return values.map((value) => value / maxValue).toList();
  }

  _ReportVendorStatusStyle _reportVendorStatusStyle(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'live':
        return const _ReportVendorStatusStyle(
          label: 'Live',
          color: Color(0xFF12B76A),
        );
      case 'top_rated':
        return const _ReportVendorStatusStyle(
          label: 'Top Rated',
          color: AppTheme.primaryColor,
        );
      case 'paused':
        return const _ReportVendorStatusStyle(
          label: 'Paused',
          color: Color(0xFF94A3B8),
        );
      default:
        return const _ReportVendorStatusStyle(
          label: 'Stable',
          color: Color(0xFF12B76A),
        );
    }
  }

  Widget _buildReportVendorImage(
    String imageUrl, {
    double width = 72,
    double height = 72,
  }) {
    final normalizedUrl = imageUrl.trim();
    Widget child;

    if (normalizedUrl.isEmpty) {
      child = const Icon(Icons.storefront_rounded, color: Colors.grey);
    } else if (normalizedUrl.startsWith('uploads/')) {
      child = Image.network(
        '${AuthService.baseUrl.replaceAll('/api', '')}/$normalizedUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    } else {
      child = Image.asset(
        normalizedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: child,
      ),
    );
  }

  int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _safeDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrencyValue(dynamic value) {
    final amount = _safeDouble(value);
    final whole = amount.truncate();
    final cents = ((amount - whole) * 100).round().abs();
    return '\$${_formatCount(whole)}.${cents.toString().padLeft(2, '0')}';
  }

  String _formatOrderTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) {
      return '';
    }

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  _OrderStatusStyle _resolveOrderStatus(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'completed':
        return const _OrderStatusStyle(
          label: 'DELIVERED',
          textColor: Color(0xFF12B76A),
          backgroundColor: Color(0xFFE7FAEF),
        );
      case 'pending':
        return const _OrderStatusStyle(
          label: 'PREPARING',
          textColor: Color(0xFFF97316),
          backgroundColor: Color(0xFFFFF1E7),
        );
      case 'cancelled':
        return const _OrderStatusStyle(
          label: 'CANCELLED',
          textColor: Color(0xFFE11D48),
          backgroundColor: Color(0xFFFFE4E8),
        );
      default:
        return const _OrderStatusStyle(
          label: 'ACTIVE',
          textColor: Color(0xFF2563EB),
          backgroundColor: Color(0xFFE8F1FF),
        );
    }
  }

  List<AdminOrderRecord> get _filteredAdminOrders {
    final query = _orderSearchController.text.trim().toLowerCase();

    return _orders.where((order) {
      final stage = _resolveAdminOrderStage(order);
      final matchesSearch =
          query.isEmpty ||
          '#ord-${order.id.toString().padLeft(4, '0')}'.toLowerCase().contains(
            query,
          ) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerEmail.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_selectedOrderFilter) {
        case AdminOrderFilter.all:
          return true;
        case AdminOrderFilter.pending:
          return stage.filter == AdminOrderFilter.pending;
        case AdminOrderFilter.preparing:
          return stage.filter == AdminOrderFilter.preparing;
        case AdminOrderFilter.outForDelivery:
          return stage.filter == AdminOrderFilter.outForDelivery;
      }
    }).toList();
  }

  _AdminOrderStageStyle _resolveAdminOrderStage(AdminOrderRecord order) {
    final normalizedStatus = order.status.trim().toLowerCase();
    if (normalizedStatus == 'completed') {
      return const _AdminOrderStageStyle(
        label: 'DELIVERED',
        textColor: Color(0xFF0E9F6E),
        backgroundColor: Color(0xFFDFF9EA),
        filter: null,
      );
    }
    if (normalizedStatus == 'cancelled') {
      return const _AdminOrderStageStyle(
        label: 'CANCELLED',
        textColor: Color(0xFFE11D48),
        backgroundColor: Color(0xFFFFE4E8),
        filter: null,
      );
    }

    final stageIndex = ((order.id <= 0 ? 1 : order.id) - 1) % 3;
    switch (stageIndex) {
      case 0:
        return const _AdminOrderStageStyle(
          label: 'PENDING',
          textColor: Color(0xFFC26B00),
          backgroundColor: Color(0xFFFFEDB8),
          filter: AdminOrderFilter.pending,
        );
      case 1:
        return const _AdminOrderStageStyle(
          label: 'PREPARING',
          textColor: Color(0xFF2563EB),
          backgroundColor: Color(0xFFE5EEFF),
          filter: AdminOrderFilter.preparing,
        );
      default:
        return const _AdminOrderStageStyle(
          label: 'ON DELIVERY',
          textColor: Color(0xFFFF6B2C),
          backgroundColor: Color(0xFFFFEDE5),
          filter: AdminOrderFilter.outForDelivery,
        );
    }
  }

  AdminRestaurantRecord? _merchantForOrder(AdminOrderRecord order) {
    if (_restaurants.isEmpty) {
      return null;
    }

    final index = ((order.id <= 0 ? 1 : order.id) - 1) % _restaurants.length;
    return _restaurants[index];
  }

  void _showOrderDetailsMessage(AdminOrderRecord order) {
    final time = _formatOrderTime(order.createdAt?.toIso8601String());
    final identity = order.customerEmail.isEmpty
        ? order.customerName
        : order.customerEmail;
    final detail = time.isEmpty ? identity : '$identity - $time';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id}: $detail'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  void _showOrderStatusMessage(
    AdminOrderRecord order,
    _AdminOrderStageStyle stage,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order #${order.id} is marked ${stage.label}. Pending orders are grouped into UI stages for this view.',
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showOrderContactMessage(AdminOrderRecord order) {
    final phone = order.customerPhone?.trim() ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          phone.isEmpty
              ? 'No phone number saved for ${order.customerName}.'
              : 'Call ${order.customerName}: $phone',
        ),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  List<AdminUserRecord> get _filteredAdminUsers {
    final query = _userSearchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch =
          query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      final status = _effectiveUserStatus(user);
      switch (_selectedUserFilter) {
        case AdminUserFilter.all:
          return user.role != 'admin';
        case AdminUserFilter.active:
          return user.role != 'admin' && status == AdminUserStatus.active;
        case AdminUserFilter.suspended:
          return user.role != 'admin' && status == AdminUserStatus.suspended;
        case AdminUserFilter.delivery:
          return user.role == 'delivery';
        case AdminUserFilter.admins:
          return user.role == 'admin';
      }
    }).toList();
  }

  String get _userSectionTitle {
    switch (_selectedUserFilter) {
      case AdminUserFilter.all:
        return 'ALL USERS';
      case AdminUserFilter.active:
        return 'ACTIVE USERS';
      case AdminUserFilter.suspended:
        return 'SUSPENDED USERS';
      case AdminUserFilter.delivery:
        return 'DELIVERY PARTNERS';
      case AdminUserFilter.admins:
        return 'ADMIN USERS';
    }
  }

  AdminUserStatus _effectiveUserStatus(AdminUserRecord user) {
    return _userStatusOverrides[user.id] ?? AdminUserStatus.active;
  }

  List<AdminUserRecord> get _customerUsers {
    return _users.where((user) => user.role != 'admin').toList();
  }

  int get _newCustomerCountLast24Hours {
    final now = DateTime.now();
    return _customerUsers.where((user) {
      final createdAt = user.createdAt;
      if (createdAt == null) {
        return false;
      }

      return now.difference(createdAt).inHours < 24;
    }).length;
  }

  String get _customerGrowthLabel {
    final now = DateTime.now();
    final currentWindowStart = now.subtract(const Duration(days: 30));
    final previousWindowStart = now.subtract(const Duration(days: 60));

    final currentCount = _customerUsers.where((user) {
      final createdAt = user.createdAt;
      return createdAt != null &&
          !createdAt.isBefore(currentWindowStart) &&
          !createdAt.isAfter(now);
    }).length;

    final previousCount = _customerUsers.where((user) {
      final createdAt = user.createdAt;
      return createdAt != null &&
          !createdAt.isBefore(previousWindowStart) &&
          createdAt.isBefore(currentWindowStart);
    }).length;

    if (previousCount <= 0) {
      return currentCount > 0 ? '+100% growth' : '0% growth';
    }

    final percent = (((currentCount - previousCount) / previousCount) * 100)
        .round();
    final sign = percent > 0 ? '+' : '';
    return '$sign$percent% growth';
  }

  String _formatUserJoined(DateTime? date) {
    if (date == null) {
      return 'Unknown';
    }

    const months = <String>[
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
    return '${months[date.month - 1]} ${date.year}';
  }

  List<Color> _avatarPaletteForUser(AdminUserRecord user) {
    const palettes = <List<Color>>[
      [Color(0xFF2563EB), Color(0xFF60A5FA)],
      [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      [Color(0xFFEA580C), Color(0xFFFB923C)],
      [Color(0xFF059669), Color(0xFF34D399)],
      [Color(0xFFBE123C), Color(0xFFFB7185)],
    ];
    final index = user.id.abs() % palettes.length;
    return palettes[index];
  }

  void _toggleUserStatus(AdminUserRecord user) {
    final nextStatus = _effectiveUserStatus(user) == AdminUserStatus.active
        ? AdminUserStatus.suspended
        : AdminUserStatus.active;

    setState(() => _userStatusOverrides[user.id] = nextStatus);

    final label = nextStatus == AdminUserStatus.active
        ? 'activated'
        : 'suspended';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.fullName} $label'),
        backgroundColor: nextStatus == AdminUserStatus.active
            ? const Color(0xFF12B76A)
            : const Color(0xFFE11D48),
      ),
    );
  }

  void _showEditUserMessage(AdminUserRecord user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit tools for ${user.fullName} can be wired next.'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    var selectedRole = 'user';
    var isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isSubmitting,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                if (!formKey.currentState!.validate() || isSubmitting) {
                  return;
                }

                setDialogState(() => isSubmitting = true);

                try {
                  await _userService.createUser(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    phoneNumber: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    role: selectedRole,
                  );

                  if (!mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  await _loadData(showLoading: false);
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${nameController.text.trim()} added successfully.',
                      ),
                      backgroundColor: const Color(0xFF12B76A),
                    ),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }

                  setDialogState(() => isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: const Color(0xFFE11D48),
                    ),
                  );
                }
              }

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                actionsPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                title: const Text(
                  'Add New User',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171212),
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create a user account and save it directly to the database.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAddUserField(
                          controller: nameController,
                          label: 'Full Name',
                          hintText: 'Enter full name',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildAddUserField(
                          controller: emailController,
                          label: 'Email',
                          hintText: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Email is required';
                            }
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildAddUserField(
                          controller: phoneController,
                          label: 'Phone Number',
                          hintText: 'Optional phone number',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _buildAddUserField(
                          controller: passwordController,
                          label: 'Password',
                          hintText: 'Create a password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => submit(),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return 'Password is required';
                            }
                            if (password.length < 6) {
                              return 'Use at least 6 characters';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: _buildAddUserInputDecoration(
                            'Select role',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'delivery',
                              child: Text('Delivery Partner'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setDialogState(() => selectedRole = value);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Add User',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    }
  }

  Widget _buildAddUserField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: _buildAddUserInputDecoration(hintText),
        ),
      ],
    );
  }

  InputDecoration _buildAddUserInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE11D48)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.4),
      ),
    );
  }

  List<AdminRestaurantRecord> get _filteredRestaurants {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _restaurants.where((record) {
      final restaurant = record.restaurant;
      final matchesSearch =
          query.isEmpty ||
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.category.toLowerCase().contains(query) ||
          restaurant.description.toLowerCase().contains(query) ||
          _restaurantCode(restaurant).toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_selectedFilter) {
        case RestaurantViewFilter.all:
          return true;
        case RestaurantViewFilter.active:
          return restaurant.isAvailable;
        case RestaurantViewFilter.inactive:
          return !restaurant.isAvailable;
        case RestaurantViewFilter.topRated:
          return restaurant.rating >= 4.7;
      }
    }).toList();

    filtered.sort((left, right) {
      final activeSort = (right.restaurant.isAvailable ? 1 : 0).compareTo(
        left.restaurant.isAvailable ? 1 : 0,
      );
      if (activeSort != 0 && _selectedFilter != RestaurantViewFilter.inactive) {
        return activeSort;
      }

      final ratingSort = right.restaurant.rating.compareTo(
        left.restaurant.rating,
      );
      if (_selectedFilter == RestaurantViewFilter.topRated && ratingSort != 0) {
        return ratingSort;
      }

      final orderSort = right.totalOrders.compareTo(left.totalOrders);
      if (orderSort != 0) {
        return orderSort;
      }

      return left.restaurant.name.toLowerCase().compareTo(
        right.restaurant.name.toLowerCase(),
      );
    });

    return filtered;
  }

  List<int> _visiblePages(int totalPages, int currentPage) {
    if (totalPages <= 3) {
      return List<int>.generate(totalPages, (index) => index);
    }

    final start = math.max(0, math.min(currentPage - 1, totalPages - 3));
    return List<int>.generate(3, (index) => start + index);
  }

  String _restaurantCode(ProductModel restaurant) {
    return '#RES-${restaurant.id.toString().padLeft(5, '0')}';
  }

  String _formatCount(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}

class _OverviewMetric {
  const _OverviewMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String badgeLabel;
  final Color badgeBackground;
  final Color badgeColor;
}

class _ReportVendorStatusStyle {
  const _ReportVendorStatusStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

class _OrderStatusStyle {
  const _OrderStatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
}

class _AdminOrderStageStyle {
  const _AdminOrderStageStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.filter,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final AdminOrderFilter? filter;
}

class _RevenueTrendPainter extends CustomPainter {
  const _RevenueTrendPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final chartHeight = size.height - 8;
    final stepX = points.length == 1
        ? size.width
        : size.width / (points.length - 1);

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    for (int index = 1; index <= 3; index++) {
      final y = chartHeight * (index / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePoints = <Offset>[];
    for (int index = 0; index < points.length; index++) {
      final normalized = points[index].clamp(0.0, 1.0).toDouble();
      final x = stepX * index;
      final y = chartHeight - (chartHeight * normalized);
      linePoints.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(linePoints.first.dx, linePoints.first.dy);
    for (int index = 1; index < linePoints.length; index++) {
      final previous = linePoints[index - 1];
      final current = linePoints[index];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x33FF6B2C), Color(0x00FF6B2C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFFF6B2C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotFillPaint = Paint()..color = const Color(0xFFFF6B2C);
    final dotStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final point in linePoints) {
      canvas.drawCircle(point, 5.5, dotFillPaint);
      canvas.drawCircle(point, 5.5, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) {
      return true;
    }

    for (int index = 0; index < points.length; index++) {
      if (oldDelegate.points[index] != points[index]) {
        return true;
      }
    }

    return false;
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.1,
      ),
    );
  }
}
