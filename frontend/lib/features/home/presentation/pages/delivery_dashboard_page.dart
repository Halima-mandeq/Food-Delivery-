import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/presentation/pages/login_page.dart';

enum _DeliveryTab { dashboard, earnings, history, profile }

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  _DeliveryTab _selectedTab = _DeliveryTab.dashboard;
  bool _isOnline = true;

  final List<({IconData icon, String title, String subtitle, double amount})>
  _activity = const [
    (
      icon: Icons.restaurant_rounded,
      title: 'Burger Haven',
      subtitle: 'Delivered at 2:30 PM',
      amount: 12.40,
    ),
    (
      icon: Icons.local_cafe_rounded,
      title: 'Morning Brews',
      subtitle: 'Delivered at 1:15 PM',
      amount: 5.20,
    ),
    (
      icon: Icons.eco_rounded,
      title: 'Daily Greens',
      subtitle: 'Delivered at 11:45 AM',
      amount: 7.80,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildCurrentTab(),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case _DeliveryTab.dashboard:
        return _buildDashboardTab();
      case _DeliveryTab.earnings:
        return _buildInfoTab(
          key: const ValueKey('earnings-tab'),
          title: 'Earnings',
          subtitle: 'This week is shaping up well.',
          primaryValue: '\$842.90',
          accentNote: '+18% compared to last week',
          items: const [
            ('Trips', '46'),
            ('Tips', '\$96.00'),
            ('Avg / Trip', '\$18.32'),
          ],
        );
      case _DeliveryTab.history:
        return _buildInfoTab(
          key: const ValueKey('history-tab'),
          title: 'History',
          subtitle: 'Completed drops from today.',
          primaryValue: '18 Trips',
          accentNote: 'Strong on-time performance',
          items: const [
            ('Artisan Pizza', '2.4 km'),
            ('Burger Haven', '1.9 km'),
            ('Morning Brews', '1.1 km'),
          ],
        );
      case _DeliveryTab.profile:
        return _buildProfileTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      key: const ValueKey('dashboard-tab'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            decoration: _cardDecoration(radius: 30),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S EARNINGS',
                  style: TextStyle(
                    color: Color(0xFF60708E),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '\$142.50',
                  style: TextStyle(
                    color: Color(0xFFFF6B2C),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(height: 22),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF00A86B),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '+12% from yesterday',
                      style: TextStyle(
                        color: Color(0xFF00A86B),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'ORDERS\nCOMPLETED',
                  value: '18',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.av_timer_rounded,
                  title: 'ONLINE TIME',
                  value: '5h 42m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Active Delivery',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                'IN PROGRESS',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActiveDeliveryCard(),
          const SizedBox(height: 28),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivityCard(limit: 2),
        ],
      ),
    );
  }

  Widget _buildInfoTab({
    required Key key,
    required String title,
    required String subtitle,
    required String primaryValue,
    required String accentNote,
    required List<(String, String)> items,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(radius: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A879A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  primaryValue,
                  style: const TextStyle(
                    color: Color(0xFFFF6B2C),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  accentNote,
                  style: const TextStyle(
                    color: Color(0xFF00A86B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: _cardDecoration(radius: 22),
              child: Row(
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.$2,
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
          if (_selectedTab == _DeliveryTab.profile) ...[
            const SizedBox(height: 6),
            _buildRecentActivityCard(limit: 3),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      key: const ValueKey('profile-tab'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(radius: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Courier Level 3',
                  style: TextStyle(
                    color: Color(0xFF7A879A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline
                        ? const Color(0xFFFF6B2C)
                        : const Color(0xFF6F8098),
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rating 4.9 | 218 deliveries',
                  style: TextStyle(
                    color: Color(0xFF00A86B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...const [
            ('Vehicle', 'Bike'),
            ('On-time', '98%'),
            ('Support', 'Available'),
          ].map(
            (item) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(22)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFFEFF3F7)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D152238),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildRecentActivityCard(limit: 3),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFD14343)),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFD14343),
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(62),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF2CACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildCourierAvatar(radius: 24),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Saffron Delivery',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentColor,
              letterSpacing: -0.8,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isOnline = !_isOnline),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isOnline
                  ? const Color(0xFFD7F8E7)
                  : const Color(0xFFE7EDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isOnline
                    ? const Color(0xFF8BE2B8)
                    : const Color(0xFFC8D3E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? const Color(0xFF07B36D)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: _isOnline
                        ? const Color(0xFF007A52)
                        : const Color(0xFF6F8098),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B2C)),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF60708E),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(
        radius: 28,
        borderColor: const Color(0xFFFFE3D4),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 74,
                  height: 74,
                  color: const Color(0xFFF5EFE8),
                  child: Image.asset(
                    'images/pizza.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_pizza_rounded,
                      color: AppTheme.primaryColor,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artisan Pizza\nCo.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentColor,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFF6F8098),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '4512 Oak Street, Unit\n4B',
                            style: TextStyle(
                              color: Color(0xFF60708E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PAYOUT',
                    style: TextStyle(
                      color: Color(0xFF9AA8BF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '\$8.50',
                    style: TextStyle(
                      color: Color(0xFFFF6B2C),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 182,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFFF3F7FB),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(painter: _RouteMapPainter()),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          '2.4 km away',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage('Opening delivery details'),
                  icon: const Icon(
                    Icons.info_rounded,
                    color: Color(0xFF1C2841),
                    size: 18,
                  ),
                  label: const Text(
                    'Details',
                    style: TextStyle(
                      color: Color(0xFF1C2841),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F4FA),
                    side: BorderSide.none,
                    minimumSize: const Size.fromHeight(72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMessage('Launching navigation'),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text(
                    'Navigate',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    backgroundColor: const Color(0xFFFF6B2C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard({required int limit}) {
    final items = _activity.take(limit).toList();
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius: 26),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      items[i].icon,
                      color: const Color(0xFF9AA8BF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].subtitle,
                          style: const TextStyle(
                            color: Color(0xFF6F8098),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${items[i].amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: Color(0xFFEAEFF5)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(
            icon: Icons.local_shipping_rounded,
            label: 'Dashboard',
            tab: _DeliveryTab.dashboard,
          ),
          _buildTabButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Earnings',
            tab: _DeliveryTab.earnings,
          ),
          _buildTabButton(
            icon: Icons.history_rounded,
            label: 'History',
            tab: _DeliveryTab.history,
          ),
          _buildTabButton(
            icon: Icons.person_rounded,
            label: 'Profile',
            tab: _DeliveryTab.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required _DeliveryTab tab,
  }) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF1E9) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFF98A7BD),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF98A7BD),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierAvatar({required double radius}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'images/unnamed (1).png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFFFE0C7),
            child: Icon(
              Icons.person_rounded,
              color: AppTheme.primaryColor,
              size: radius,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 24,
    Color borderColor = const Color(0xFFEFF3F7),
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF152238).withValues(alpha: 0.05),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFDCE9B7));
    canvas.drawOval(
      Rect.fromLTWH(-size.width * 0.22, 0, size.width * 0.55, size.height),
      Paint()..color = const Color(0xFFCFE5F1),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.75, -12, size.width * 0.34, size.height * 1.1),
      Paint()..color = const Color(0xFFEAF1E0),
    );

    final roadPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
    final routePaint =
        Paint()
          ..color = const Color(0xFFE36363)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8;

    final roads = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.15)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.20,
          size.width * 0.45,
          size.height * 0.05,
        )
        ..quadraticBezierTo(
          size.width * 0.62,
          size.height * 0.14,
          size.width * 0.88,
          size.height * 0.08,
        ),
      Path()
        ..moveTo(size.width * 0.18, size.height * 0.92)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.70,
          size.width * 0.52,
          size.height * 0.62,
        )
        ..quadraticBezierTo(
          size.width * 0.66,
          size.height * 0.52,
          size.width * 0.84,
          size.height * 0.32,
        ),
      Path()
        ..moveTo(size.width * 0.60, 0)
        ..quadraticBezierTo(
          size.width * 0.48,
          size.height * 0.28,
          size.width * 0.58,
          size.height * 0.50,
        )
        ..quadraticBezierTo(
          size.width * 0.67,
          size.height * 0.74,
          size.width * 0.54,
          size.height,
        ),
    ];
    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.32, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.35,
        size.width * 0.42,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.63,
        size.width * 0.64,
        size.height * 0.78,
      );
    canvas.drawPath(route, routePaint);

    final pointPaint = Paint()..color = Colors.white;
    final pointBorder =
        Paint()
          ..color = const Color(0xFFE36363)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
    final points = [
      Offset(size.width * 0.32, size.height * 0.18),
      Offset(size.width * 0.34, size.height * 0.29),
      Offset(size.width * 0.37, size.height * 0.39),
      Offset(size.width * 0.42, size.height * 0.48),
      Offset(size.width * 0.50, size.height * 0.58),
      Offset(size.width * 0.58, size.height * 0.68),
      Offset(size.width * 0.64, size.height * 0.78),
    ];
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 4, pointBorder);
    }
    final pinCenter = Offset(size.width * 0.66, size.height * 0.26);
    canvas.drawCircle(
      pinCenter,
      6,
      Paint()..color = const Color(0xFFFF6B2C),
    );
    canvas.drawCircle(pinCenter, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
