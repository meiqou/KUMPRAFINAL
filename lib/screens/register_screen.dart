import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  List<dynamic> _clusters = [];
  String? _selectedClusterId;
  bool _loading = false;
  bool _fetchingClusters = true;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    final res = await AuthService.getClusters();
    if (mounted) {
      setState(() {
        _clusters = res['clusters'] ?? [];
        _fetchingClusters = false;
      });
    }
  }

  void _register() async {
    if (_nameController.text.isEmpty || _selectedClusterId == null || _passwordController.text.length < 6) {
      _showSnack('Please fill all required fields correctly.');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.register(
      _nameController.text.trim(),
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text.trim(),
      _selectedClusterId!,
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
      _showSnack(res['message'] ?? 'Registration failed');
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.primary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text('Join the Kumpra community', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _buildField(_nameController, 'FULL NAME', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(_usernameController, 'USERNAME', Icons.alternate_email),
            const SizedBox(height: 16),
            _buildField(_emailController, 'EMAIL ADDRESS', Icons.mail_outline),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'PHONE NUMBER (09xxxxxxxxx)', Icons.phone_android),
            const SizedBox(height: 16),
            _buildField(_passwordController, 'PASSWORD', Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _fetchingClusters 
                ? const LinearProgressIndicator()
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('SELECT BARANGAY', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                      value: _selectedClusterId,
                      items: _clusters.map((c) => DropdownMenuItem(
                        value: c['cluster_id'].toString(),
                        child: Text(c['barangay_name'] ?? '', style: GoogleFonts.poppins(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedClusterId = v),
                    ),
                  ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: AppColors.primaryDark) 
                  : Text('SIGN UP', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 16)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight),
          border: InputBorder.none,
        ),
      ),
    );
  }
}