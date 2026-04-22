import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/rider_auth_service.dart';
import 'rider_home_screen.dart';

class RiderRegisterScreen extends StatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  State<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends State<RiderRegisterScreen> {
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _workShift = 'Morning';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_nameController.text.isEmpty || _plateController.text.isEmpty || _passwordController.text.length < 6) {
      _showSnack('Please fill all fields correctly.');
      return;
    }

    setState(() => _loading = true);
    final res = await RiderAuthService.register(
      name: _nameController.text.trim(),
      plateNumber: _plateController.text.trim(),
      phone: _phoneController.text.trim(),
      workShift: _workShift,
      password: _passwordController.text.trim(),
    );
    setState(() => _loading = false);

    if (res['success'] == true) {
      await RiderAuthService.saveSession(res['rider']);
      if (mounted) {
        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RiderHomeScreen()));
      }
    } else {
      _showSnack(res['message'] ?? 'Registration failed');
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
Text('Join Rider Team', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 32),
            _buildField(_nameController, 'FULL NAME', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_plateController, 'PLATE NUMBER', Icons.motorcycle),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'MOBILE NUMBER', Icons.phone_android),
            const SizedBox(height: 16),
            _buildField(_passwordController, 'PASSWORD', Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _workShift,
                  isExpanded: true,
                  items: ['Morning', 'Afternoon', 'Evening'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _workShift = v!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER AS RIDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight),
          border: InputBorder.none,
        ),
      ),
    );
  }
}