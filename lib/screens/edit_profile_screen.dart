import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<dynamic> _clusters = [];
  String _selectedClusterId = '';
  String _selectedClusterName = 'Select Your Barangay';
  String _selectedClusterZone = '';

  bool _loading = false;
  bool _fetchingClusters = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadClusters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('user_email') ?? '';
    final storedUserData = prefs.getString('user_data');
    if (storedUserData != null) {
      try {
        final parsed = jsonDecode(storedUserData);
        if (parsed is Map<String, dynamic>) {
          email = parsed['email'] ?? email;
        }
      } catch (_) {
        // ignore invalid stored data
      }
    }

    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _usernameController.text = prefs.getString('user_username') ?? '';
      _emailController.text = email;
      _selectedClusterId = prefs.getString('cluster_id') ?? '';
      _selectedClusterName =
          prefs.getString('cluster_name') ?? 'Select Your Barangay';
    });
  }

  Future<void> _loadClusters() async {
    final res = await AuthService.getClusters();
    if (res['success'] == true) {
      final clusters = res['clusters'] ?? [];
      setState(() {
        _clusters = clusters;
        _fetchingClusters = false;
      });
      _syncSelectedCluster(clusters);
    } else {
      setState(() => _fetchingClusters = false);
      _showSnack('Unable to load barangays for profile update.');
    }
  }

  void _syncSelectedCluster(List<dynamic> clusters) {
    if (_selectedClusterId.isEmpty && clusters.isNotEmpty) {
      final firstCluster = clusters.first;
      setState(() {
        _selectedClusterId = firstCluster['cluster_id'].toString();
        _selectedClusterName = firstCluster['name'] ?? 'Select Your Barangay';
        _selectedClusterZone = firstCluster['street_zone'] ?? '';
      });
      return;
    }

    final selected = clusters.firstWhere(
      (c) => c['cluster_id'].toString() == _selectedClusterId,
      orElse: () => null,
    );
    if (selected != null) {
      setState(() {
        _selectedClusterName = selected['name'] ?? _selectedClusterName;
        _selectedClusterZone = selected['street_zone'] ?? '';
      });
    }
  }

  void _showClusterPicker() {
    if (_fetchingClusters) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: ListView.builder(
          itemCount: _clusters.length,
          itemBuilder: (context, index) {
            final c = _clusters[index];
            return ListTile(
              title: Text(c['name'] ?? ''),
              subtitle: Text(c['street_zone'] ?? ''),
              onTap: () {
                setState(() {
                  _selectedClusterId = c['cluster_id'].toString();
                  _selectedClusterName = c['name'] ?? 'Select Your Barangay';
                  _selectedClusterZone = c['street_zone'] ?? '';
                });
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      _showSnack('Name and username cannot be empty.');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    if (_selectedClusterId.isEmpty) {
      _showSnack('Please choose a barangay.');
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.updateProfile(
      name,
      username,
      email,
      password,
      _selectedClusterId,
    );
    setState(() => _loading = false);

    if (res['success'] == true) {
      if (res['user'] is Map<String, dynamic>) {
        await AuthService.saveSession(res['user'] as Map<String, dynamic>);
      }
      _showSnack('Profile successfully updated.');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      final detailedMsg = res['message'] ?? 'Unable to update profile';
      _showSnack('Update failed: $detailedMsg');
      print('Profile update error: $res'); // DEBUG log
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscureText,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight),
          hintText: hint,
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update your profile information',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildField(
              controller: _nameController,
              label: 'FULL NAME',
              hint: 'Juan Dela Cruz',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _usernameController,
              label: 'USERNAME',
              hint: 'johndoe',
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _emailController,
              label: 'EMAIL',
              hint: 'name@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _passwordController,
              label: 'PASSWORD',
              hint: 'Leave blank to keep current password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showClusterPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR BARANGAY',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight)),
                          Text(_selectedClusterName.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          if (_selectedClusterZone.isNotEmpty)
                            Text(_selectedClusterZone,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('SAVE CHANGES',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
