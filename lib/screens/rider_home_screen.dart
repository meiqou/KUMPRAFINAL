import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/rider_auth_service.dart';
import 'onboarding_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  List<dynamic> _availableBatches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchAvailableBatches());
  }

  Future<void> _fetchAvailableBatches({int? clusterId}) async {
    setState(() => _loading = true);
    final params = clusterId != null ? {'cluster_id': clusterId.toString()} : null;
    final res = await ApiService.get('riders/batches/available.php', auth: true, params: params);
    if (mounted) {
      setState(() {
        _availableBatches = res['batches'] ?? [];
        _loading = false;
      });
    }
  }

  void _acceptBatch(int batchId) async {
    final res = await ApiService.post('riders/batches/accept.php', {'batch_id': batchId}, auth: true);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch accepted!'), backgroundColor: AppColors.success));
      await _fetchAvailableBatches();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to accept')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Available Batches', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await RiderAuthService.logout();
              if (context.mounted) {
                await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()), (_) => false);
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAvailableBatches,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _availableBatches.isEmpty
                ? Center(child: Text('No batches waiting for a rider.', style: GoogleFonts.poppins()))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _availableBatches.length,
                    itemBuilder: (context, index) {
                      final batch = _availableBatches[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(batch['name'] ?? 'Batch #${batch['batch_id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18)),
                                  Text('₱${batch['shared_fee']}', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Barangay: ${batch['cluster_name']}', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              Text('Items: ${batch['joined']} users', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              const Divider(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _acceptBatch(batch['batch_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('ACCEPT BATCH'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
