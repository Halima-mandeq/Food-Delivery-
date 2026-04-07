import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key, required this.user});

  final UserModel user;

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isSaving = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool get _requiresCurrentPassword {
    final emailChanged =
        _emailController.text.trim().toLowerCase() !=
        widget.user.email.trim().toLowerCase();
    return emailChanged || _newPasswordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _emailController.addListener(_refreshPasswordRequirement);
    _newPasswordController.addListener(_refreshPasswordRequirement);
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshPasswordRequirement);
    _newPasswordController.removeListener(_refreshPasswordRequirement);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshPasswordRequirement() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final userId = widget.user.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account cannot be updated right now.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await _authService.updateProfile(
      userId: userId,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      currentPassword: _currentPasswordController.text.trim().isEmpty
          ? null
          : _currentPasswordController.text,
      newPassword: _newPasswordController.text.isEmpty
          ? null
          : _newPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(result['user'] as UserModel);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['error']?.toString() ?? 'Failed to update profile',
        ),
        backgroundColor: const Color(0xFFE11D48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.accentColor,
        elevation: 0,
        title: const Text(
          'Profile Info',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _buildIntroCard(),
              const SizedBox(height: 20),
              _buildFormCard(),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Update your profile',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _requiresCurrentPassword
                ? 'Current password is required because you are changing your email or password.'
                : 'Change your name, email, phone number, or set a new password.',
            style: const TextStyle(
              color: Color(0xFF6B7A90),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF152238).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildField(
            controller: _fullNameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _emailController,
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
          const SizedBox(height: 16),
          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: 'Optional phone number',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _currentPasswordController,
            label: 'Current Password',
            hintText: _requiresCurrentPassword
                ? 'Required for email or password changes'
                : 'Only needed for secure changes',
            obscureText: _obscureCurrentPassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
              icon: Icon(
                _obscureCurrentPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
            validator: (value) {
              if (_requiresCurrentPassword &&
                  (value == null || value.isEmpty)) {
                return 'Current password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _newPasswordController,
            label: 'New Password',
            hintText: 'Leave blank to keep your current password',
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.isNotEmpty && password.length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hintText: 'Repeat the new password',
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _saveProfile(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
            validator: (value) {
              if (_newPasswordController.text.isEmpty) {
                return null;
              }
              if (value == null || value.isEmpty) {
                return 'Confirm the new password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F5F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E2DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE11D48)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
        ),
      ),
    );
  }
}
