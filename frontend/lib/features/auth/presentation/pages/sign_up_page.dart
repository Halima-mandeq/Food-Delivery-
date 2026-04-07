import 'package:flutter/material.dart';
import 'package:food_delivery_frontend/core/theme/app_theme.dart';
import 'package:food_delivery_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:food_delivery_frontend/features/auth/data/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);

    final result = await _authService.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      // Navigate to Login after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sign Up",
          style: TextStyle(
            color: AppTheme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Create your account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Join our food community and get fresh meals delivered to your doorstep.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),


            // Full Name
            _buildLabel("Full Name"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _fullNameController,
              hintText: "Enter your full name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),

            // Email
            _buildLabel("Email"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hintText: "Enter your email address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Phone Number
            _buildLabel("Phone Number"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _phoneController,
              hintText: "+1 (555) 000-0000",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            _buildLabel("Account Type"),
            const SizedBox(height: 8),
            _buildRoleSelector(),
            const SizedBox(height: 24),

            // Password
            _buildLabel("Password"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              hintText: "Create a password",
              icon: Icons.lock_outline,
              obscureText: true,
              suffixIcon: const Icon(Icons.visibility_outlined, color: Colors.blueGrey),
            ),
            const SizedBox(height: 40),

            // Create Account Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Create Account",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms of Service
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                  children: const [
                    TextSpan(text: "By signing up, you agree to our "),
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Footer
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }


  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFECE5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.blueGrey.shade300, size: 22),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.blueGrey.shade200, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFECE5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(
              value: 'user',
              child: Text('Customer Account'),
            ),
            DropdownMenuItem(
              value: 'delivery',
              child: Text('Delivery Partner Account'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedRole = value);
          },
        ),
      ),
    );
  }
}
