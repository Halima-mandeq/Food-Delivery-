import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({
    super.key,
    this.user,
    required this.onActionSelected,
    required this.onSignOut,
  });

  final UserModel? user;
  final ValueChanged<String> onActionSelected;
  final VoidCallback onSignOut;

  static const List<_ProfileStatData> _stats = [
    _ProfileStatData(
      label: 'ORDERS',
      value: '24',
      valueColor: AppTheme.primaryColor,
    ),
    _ProfileStatData(
      label: 'POINTS',
      value: '1.2k',
      valueColor: AppTheme.primaryColor,
    ),
    _ProfileStatData(
      label: 'STATUS',
      value: 'Gold',
      valueColor: AppTheme.primaryColor,
    ),
  ];

  static const List<_ProfileMenuItemData> _accountItems = [
    _ProfileMenuItemData(
      title: 'Profile Info',
      icon: Icons.person_rounded,
      iconBackground: Color(0xFFFFF0E8),
      iconColor: AppTheme.primaryColor,
    ),
  ];

  String get _displayName {
    final fullName = user?.fullName.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    return 'Alex Saffron';
  }

  String get _displayEmail {
    final email = user?.email.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'alex.saffron@horizon.com';
  }

  String get _headlineLocation {
    if (user == null) {
      return 'Saffron Horizon';
    }

    final nameParts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final anchor = nameParts.isNotEmpty ? nameParts.last : 'Wagba';
    final emailParts = _displayEmail.split('@');
    final domain = emailParts.length > 1
        ? emailParts.last.split('.').first
        : 'Home';

    return '${_titleCase(anchor)} ${_titleCase(domain)}';
  }

  String get _avatarLabel {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return 'AS';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('profile-tab'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _buildHeader(),
        const SizedBox(height: 26),
        _buildProfileHero(),
        const SizedBox(height: 28),
        Row(
          children: [
            for (var index = 0; index < _stats.length; index++) ...[
              Expanded(child: _buildStatCard(_stats[index])),
              if (index != _stats.length - 1) const SizedBox(width: 14),
            ],
          ],
        ),
        const SizedBox(height: 34),
        _buildSectionLabel('MY ACCOUNT'),
        const SizedBox(height: 14),
        _buildMenuGroup(
          items: _accountItems,
          onTap: (title) => onActionSelected(title),
        ),
        const SizedBox(height: 28),
        _buildSignOutButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _headlineLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF202733),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFE0D0), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF162033).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _avatarLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHero() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E2632),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF162033).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.phone_iphone_rounded,
                    color: Color(0xFFD6DCE6),
                    size: 76,
                  ),
                  Positioned(
                    bottom: 34,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE3E8F0)),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF5B677C),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -4,
              bottom: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onActionSelected('Edit profile photo'),
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          _displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _displayEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5E7191),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(_ProfileStatData stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0ECE6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF162033).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5F7090),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stat.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: stat.valueColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF5F7090),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildMenuGroup({
    required List<_ProfileMenuItemData> items,
    required ValueChanged<String> onTap,
  }) {
    return Container(
      decoration: _groupDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _buildMenuRow(
              item: items[index],
              onTap: () => onTap(items[index].title),
            ),
            if (index != items.length - 1) _buildDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required _ProfileMenuItemData item,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: Color(0xFF5F7090),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA7BB),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF1ECE7)),
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton.icon(
      onPressed: onSignOut,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF473A),
        side: const BorderSide(color: Color(0xFFFFD2CB)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white.withValues(alpha: 0.35),
      ),
      icon: const Icon(Icons.logout_rounded, size: 22),
      label: const Text(
        'Sign Out',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  BoxDecoration _groupDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFF0ECE6)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF162033).withValues(alpha: 0.04),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;
}

class _ProfileMenuItemData {
  const _ProfileMenuItemData({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}
