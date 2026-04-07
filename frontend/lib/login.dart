import 'package:flutter/material.dart';
import 'register.dart';
import 'shared_ui.dart';
import 'services/api_service.dart';
import 'pages/user_home.dart';
import 'pages/admin_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Standard Validations
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.loginUser(
        email: email,
        password: password,
      );

      setState(() => isLoading = false);

      if (result['success']) {
        _showSnackBar('Welcome back! Logging you in...', Colors.green);

        final userData = result['data']['user'];
        final isAdmin = result['data']['is_admin'] ?? false;

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? AdminHomePage(userData: userData)
                : UserHomePage(userData: userData),
          ),
        );
      } else {
        // Professional Specific Error Handling
        String serverError = result['error'].toString().toLowerCase();

        if (serverError.contains('email') ||
            serverError.contains('not found')) {
          _showSnackBar(
            'This email is not registered. Please create an account.',
            Colors.blueGrey,
          );
        } else if (serverError.contains('password') ||
            serverError.contains('credentials')) {
          _showSnackBar(
            'Incorrect password. Please try again.',
            Colors.redAccent,
          );
        } else {
          _showSnackBar(result['error'], Colors.red);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Server connection failed.', Colors.red);
    }
  }

  // Helper method to keep code clean
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: "Login",
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_person_rounded,
              size: 60,
              color: Colors.lightGreenAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in to continue",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Email Field
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.lightGreenAccent,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.lightGreenAccent,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: handleLogin, // UPDATED
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigate to Register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.lightGreenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
