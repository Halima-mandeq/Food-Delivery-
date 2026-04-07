import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/data/models/user_model.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/home_page.dart';
import 'package:food_delivery_frontend/features/auth/presentation/pages/sign_up_page.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';
import 'package:food_delivery_frontend/features/home/presentation/pages/delivery_dashboard_page.dart';

import 'package:food_delivery_frontend/features/admin/presentation/pages/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      final user = result['user'] as UserModel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Welcome back, ${user.fullName}! Logged in as ${user.role}",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Home or Admin Dashboard depending on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (user.role == 'admin') {
              return const AdminDashboard();
            }
            if (user.role == 'delivery') {
              return const DeliveryDashboardPage();
            }
            return HomePage(user: user);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.accentColor,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F2F6),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Sign In",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: AppTheme.accentColor,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Access your favorite meals faster",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            _buildLabel("Email Address"),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              hintText: "example@gmail.com",
            ),
            const SizedBox(height: 24),
            _buildLabel("Password"),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _passwordController,
              hintText: "Enter your password",
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  elevation: 10,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[200])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Social Login",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[200])),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildSocialButton(Icons.g_mobiledata_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildSocialButton(Icons.apple_rounded)),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "New to Wagba? ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F2F6), width: 2),
      ),
      child: Icon(icon, color: AppTheme.accentColor, size: 32),
    );
  }
}
