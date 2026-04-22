import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'rider_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _login() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Please enter your credentials');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.login(
      _identifierController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _loading = false);

    if (res['success'] == true) {
      await AuthService.saveSession(res['user']);
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      _showSnack(res['message'] ?? 'Login failed');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text('Welcome Back', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Text('Log in to continue with Kumpra', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 48),
              _buildInput(_identifierController, 'USERNAME, EMAIL, OR PHONE', Icons.person_outline),
              const SizedBox(height: 16),
              _buildInput(_passwordController, 'PASSWORD', Icons.lock_outline, obscure: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading 
                    ? const CircularProgressIndicator(color: AppColors.primaryDark) 
                    : Text('LOG IN', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Don\'t have an account? Sign up', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                const Divider(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
                  ),
                  icon: const Icon(Icons.motorcycle, size: 20),
                  label: Text('LOG IN AS RIDER',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}