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

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      _showSnack('Enter your username, mobile number, or email');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Enter your password');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.login(identifier, password);
    setState(() => _loading = false);

    if (res['success'] == true) {
      await AuthService.saveSession(res['user']);
      if (mounted) {
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      _showSnack(res['message'] ?? 'Login failed');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primaryDark,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'KUMPRA',
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // LOGIN IDENTIFIER FIELD
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44, margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.alternate_email, color: AppColors.primary)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _identifierController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'username, phone, or email',
                          hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                          labelText: 'USERNAME / PHONE / EMAIL',
                          labelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 1),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(right: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PASSWORD FIELD
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44, margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.lock_outline, color: AppColors.primary)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                          labelText: 'PASSWORD',
                          labelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 1),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(right: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('LOGIN', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 40),
              
              // SIGN UP LINK
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
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
        ),
      ),
    );
  }
}