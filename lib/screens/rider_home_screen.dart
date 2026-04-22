import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/rider_auth_service.dart';
import '../services/rider_geolocation_service.dart';
import 'onboarding_screen.dart';
import 'batch_route_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  List<dynamic> _availableBatches = [];
  Map<String, dynamic>? _acceptedBatch;
  bool _showAccepted = false;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchAvailableBatches();
  }

  Future<void> _fetchAvailableBatches({int? clusterId}) async {
    setState(() => _loading = true);
    final params = clusterId != null ? {'cluster_id': clusterId.toString()} : null; // This _loading is for available batches
    final res = await ApiService.get('batches/available.php', auth: true, params: params);
    if (mounted) {
      setState(() {
        _availableBatches = res['batches'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    RiderGeolocationService.stopTracking();
    super.dispose();
  }

  Future<void> _fetchMyBatch() async {
    try {
      final res = await ApiService.get('batches/my.php', auth: true);
      if (mounted && res['success'] == true && res['batches'] != null && (res['batches'] as List).isNotEmpty) {
        setState(() {
          _acceptedBatch = res['batches'][0];
        });
      } else if (mounted) {
        setState(() {
          _showAccepted = false;
        });
      }
    } catch (e) {
      print('Error fetching my batch: $e');
    }
  }

  void _startPollingMyBatch() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchMyBatch();
    });
  }

  Future<void> _acceptBatch(int batchId) async {
    final res = await ApiService.post('batches/accept.php', {'batch_id': batchId}, auth: true);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch accepted! GPS tracking started'), backgroundColor: AppColors.success));
      await RiderGeolocationService.startTracking(batchId);
      await _fetchMyBatch();
      if (mounted) {
        setState(() => _showAccepted = true);
        _startPollingMyBatch();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to accept')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _showAccepted && _acceptedBatch != null && !_loadingAcceptedBatchDetails
            ? 'My Batch: ${_acceptedBatch!['name']}'
            : 'Available Batches', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await RiderAuthService.logout();
              if (context.mounted) {
                await Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()), (route) => false);
              }
            },
          )
        ],
      ),
      body: _showAccepted && _acceptedBatch != null && !_loadingAcceptedBatchDetails // Only show accepted batch if not loading its details
        ? ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.success.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _acceptedBatch!['name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800, 
                              fontSize: 20, 
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '₱${_acceptedBatch!['shared_fee']}',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Barangay: ${_acceptedBatch!['cluster_name']}', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      Text('${_acceptedBatch!['joined']} customers', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      Text('Status: ${_acceptedBatch!['status']}', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BatchRouteScreen(
                                    batchId: _acceptedBatch!['batch_id'],
                                    clusterLat: (_acceptedBatch!['latitude'] as num?)?.toDouble() ?? 10.6765,
                                    clusterLng: (_acceptedBatch!['longitude'] as num?)?.toDouble() ?? 122.9513,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.route, size: 20),
                              label: const Text('View Route'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BatchCustomersMapScreen(
                                    batchId: _acceptedBatch!['batch_id'],
                                    clusterLat: (_acceptedBatch!['latitude'] as num?)?.toDouble() ?? 10.6765,
                                    clusterLng: (_acceptedBatch!['longitude'] as num?)?.toDouble() ?? 122.9513,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.people_alt, size: 20),
                              label: const Text('Customers'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Other Available Batches',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              if (_availableBatches.isNotEmpty)
                ..._availableBatches.map((batch) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                batch['name'] ?? 'Batch #${batch['batch_id']}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              Text(
                                '₱${batch['shared_fee']}',
                                style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Barangay: ${batch['cluster_name']}', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          Text('${batch['joined']} users', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
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
                  ),
                )),
            ],
          )
        : RefreshIndicator(
            onRefresh: _fetchAvailableBatches,
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _availableBatches.isEmpty
                ? Center(
                    child: Text('No batches waiting for a rider.', style: GoogleFonts.poppins()),
                  )
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
                                  Text(
                                    batch['name'] ?? 'Batch #${batch['batch_id']}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
                                  ),
                                  Text(
                                    '₱${batch['shared_fee']}',
                                    style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Barangay: ${batch['cluster_name']}', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              Text('${batch['joined']} users', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
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
