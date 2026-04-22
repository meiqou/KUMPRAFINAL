import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/rider_auth_service.dart';
import 'rider_home_screen.dart';
import 'login_screen.dart';
import 'rider_register_screen.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    final res = await RiderAuthService.login(_identifierController.text.trim(), _passwordController.text.trim());
    setState(() => _loading = false);

    if (res['success'] == true) {
      await RiderAuthService.saveSession(res['rider']);
      if (mounted) {
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RiderHomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
Text('Rider Dashboard', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 40),
              _buildInput(_identifierController, 'ACCOUNT NUMBER OR USERNAME', Icons.person_outline),
              const SizedBox(height: 16),
              _buildInput(_passwordController, 'PASSWORD', Icons.lock_outline, obscure: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('LOGIN'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderRegisterScreen())),
                  child: const Text('Don\'t have a rider account? Register here'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text('Log in as Customer instead',
                      style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}