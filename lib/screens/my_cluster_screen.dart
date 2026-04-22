import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MyClusterScreen extends StatefulWidget {
  const MyClusterScreen({super.key});

  @override
  State<MyClusterScreen> createState() => _MyClusterScreenState();
}

class _MyClusterScreenState extends State<MyClusterScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _cluster;
  List<dynamic> _batches = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadClusterData();
  }

  Future<void> _loadClusterData() async {
    if (!mounted) return;
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      // Get user data from prefs
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        try {
          final userData = Map<String, dynamic>.from(jsonDecode(userDataStr));
          setState(() => _userData = userData);
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }

      // Get clusters
      final clustersRes = await AuthService.getClusters();
      if (clustersRes['success'] == true && _userData != null) {
        final clusters = List<Map<String, dynamic>>.from(clustersRes['clusters'] ?? []);
        final clusterId = _userData!['cluster_id']?.toString();
        final userCluster = clusters.firstWhere(
          (c) => c['cluster_id'].toString() == clusterId,
          orElse: () => {},
        );
        if (userCluster.isNotEmpty) {
          setState(() => _cluster = userCluster);
        }
      }

      // Get batches for this cluster
      if (_cluster != null) {
        final batchesRes = await ApiService.get('batches/list.php', auth: true, params: {
          'cluster_id': _cluster!['cluster_id'].toString(),
        });
        if (batchesRes['success'] == true) {
          setState(() => _batches = List.from(batchesRes['batches'] ?? []));
        }
      }
    } catch (e) {
      setState(() => _error = 'Error loading cluster: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinBatch(String batchId) async {
    final res = await ApiService.post('batches/join.php', {'batch_id': batchId}, auth: true);
    if (res['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined batch!'), backgroundColor: AppColors.success),
      );
      await _loadClusterData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'Join failed'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Cluster', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadClusterData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                : _cluster == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text('No cluster assigned', style: GoogleFonts.poppins(fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Update your profile to join a cluster', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cluster Header
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_city, color: AppColors.primary, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _cluster!['barangay_name'] ?? _cluster!['name'] ?? 'Cluster',
                                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800),
                                              ),
                                              Text(
                                                _cluster!['street_zone'] ?? '',
                                                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${_batches.length} active batch${_batches.length != 1 ? 'es' : ''}',
                                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Active Batches
                            Text(
                              'Active Batches',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            ..._batches.map((batch) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.group, color: AppColors.primary),
                                    ),
                                    title: Text(
                                      batch['batch_name'] ?? 'Batch ${batch['batch_id']}',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${batch['member_count'] ?? 0} members'),
                                        Text('Fee: ₱${batch['delivery_fee'] ?? 0}'),
                                      ],
                                    ),
                                    trailing: SizedBox(
                                      width: 80,
                                      child: ElevatedButton(
                                        onPressed: batch['is_joined'] == true
                                            ? null
                                            : () => _joinBatch(batch['batch_id'].toString()),
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                        child: Text(batch['is_joined'] == true ? 'Joined' : 'Join', style: const TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    onTap: () {},
                                  ),
                                )),
                            if (_batches.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    const Icon(Icons.group_outlined, size: 64, color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    Text('No active batches', style: GoogleFonts.poppins(fontSize: 16)),
                                    Text('Batches will appear here when available', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
