import 'package:flutter/material.dart';
import 'login.dart';
import 'shared_ui.dart';
import 'services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedSoft = Color(0xFFFFE5E6);
const Color kBgLight = Color(0xFFFDF7F7);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void handleRegister() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showSnackBar('Please fill all fields!', Colors.orange);
      return;
    }

    setState(() => isLoading = true);
    print('🔵 Button pressed, calling API...');

    try {
      final result = await ApiService.registerUser(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);
      print('🔵 API Result: $result');

      if (result['success']) {
        _showSnackBar('✅ Registration Successful!', kBrandRed);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        _showSnackBar('❌ Error: ${result['error']}', Colors.red,
            duration: const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('🔴 Exception in handleRegister: $e');
      _showSnackBar('❌ Exception: $e', Colors.red,
          duration: const Duration(seconds: 5));
    }
  }

  void _showSnackBar(String message, Color color,
      {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: "Register",
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandRed.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join us — it only takes a minute",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 32),

              GlassTextField(
                hintText: "Full Name",
                icon: Icons.person_outline,
                controller: nameController,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                hintText: "Email",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              const SizedBox(height: 28),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: kBrandRed.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "REGISTER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigate to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: kBrandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
