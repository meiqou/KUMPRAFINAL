import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import 'market_rows_screen.dart';
import 'basket_screen.dart';
import 'order_tracking_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<State<OrderTrackingScreen>> _orderTrackingKey = GlobalKey<State<OrderTrackingScreen>>();

  int _tab = 0;
  String _clusterName = '';
  List<dynamic> _batches = [];
  bool _loading = true;
  bool _creatingBatch = false;
  String? _joinedBatchId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final clusterId = prefs.getString('cluster_id') ?? '0';
    setState(() {
      _clusterName = prefs.getString('cluster_name') ?? 'Bacolod';
      _joinedBatchId = prefs.getString('joined_batch_id');
      _loading = true;
    });

    if (clusterId == '0' || clusterId.isEmpty) {
      setState(() {
        _batches = [];
        _loading = false;
      });
      return;
    }

    final res = await ApiService.get('batches/list.php',
        auth: true, params: {'cluster_id': clusterId});
    if (mounted) {
      setState(() {
        _batches = res['batches'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          _buildBatchList(),
          const MarketRowsScreen(),
          const BasketScreen(),
          OrderTrackingScreen(key: _orderTrackingKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(cart.count),
    );
  }

  Widget _buildBatchList() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              _clusterName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _creatingBatch ? null : _createBatch,
                    icon: _creatingBatch
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      _creatingBatch ? 'CREATING BATCH...' : 'CREATE NEW BATCH',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'New batches need at least 3 of 6 users before the rider departs.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Text(
              'AVAILABLE BATCHES TODAY',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_batches.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No batches available yet.\nCreate one and invite your cluster members to join.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final batch = _batches[i];
                  return _BatchCard(
                    batch: batch,
                    isJoined: _joinedBatchId == batch['batch_id'].toString(),
                    onJoin: () => _joinBatch(batch),
                  );
                },
                childCount: _batches.length,
              ),
            ),
          ),
      ],
    );
  }

  void _createBatch() async {
    setState(() => _creatingBatch = true);
    final prefs = await SharedPreferences.getInstance();
    var clusterId = prefs.getString('cluster_id') ?? '0';

    if (clusterId == '0' || clusterId.isEmpty) {
      final clustersRes = await AuthService.getClusters();
      final clusters = clustersRes['clusters'];
      if (clusters is List) {
        for (final cluster in clusters) {
          if (cluster is Map &&
              (cluster['name']?.toString().toLowerCase() ==
                  _clusterName.toLowerCase())) {
            clusterId = cluster['cluster_id'].toString();
            await prefs.setString('cluster_id', clusterId);
            break;
          }
        }
      }
    }

    if (clusterId == '0' || clusterId.isEmpty) {
      setState(() => _creatingBatch = false);
      _showSnack('Could not determine your barangay. Please log in again.');
      return;
    }

    final res = await ApiService.post(
        'batches/create.php',
        {
          'cluster_id': clusterId,
          'size_limit': 6,
        },
        auth: true);

    setState(() => _creatingBatch = false);
    if (res['success'] == true) {
      _showSnack(
        'Batch created. Invite 3–6 people to join before the rider departs.',
        backgroundColor: AppColors.success,
      );
      await _loadData();
    } else {
      _showSnack(res['message'] ?? 'Failed to create batch');
    }
  }

  void _joinBatch(Map<String, dynamic> batch) async {
    final res = await ApiService.post(
      'batches/join.php',
      {'batch_id': batch['batch_id']},
      auth: true,
    );

    if (res['success'] == true) {
      final batchIdStr = batch['batch_id'].toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('joined_batch_id', batchIdStr);
      setState(() => _joinedBatchId = batchIdStr);
      _showSnack('Joined ${batch['name']}! Now add items to your basket.',
          backgroundColor: AppColors.success);
      setState(() => _tab = 2);
      await _loadData();
    } else {
      _showSnack(res['message'] ?? 'Could not join batch');
    }
  }

  void _showSnack(String msg, {Color backgroundColor = AppColors.error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _setTab(int index) {
    setState(() => _tab = index);
    if (index == 3) {
      final currentState = _orderTrackingKey.currentState;
      if (currentState != null) {
        (currentState as dynamic).refreshOrder();
      }
    }
  }

  Widget _buildNavBar(int cartCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withValues(alpha: 0.2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.layers_rounded, 0),
              _navItem(Icons.home_rounded, 1),
              _cartNavItem(cartCount),
              _navItem(Icons.receipt_long_rounded, 3),
              _navItem(Icons.person_rounded, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _setTab(index),
      child: Icon(
        icon,
        color: _tab == index ? AppColors.primary : Colors.white38,
        size: 26,
      ),
    );
  }

  Widget _cartNavItem(int count) {
    return GestureDetector(
      onTap: () => setState(() => _tab = 2),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_basket_rounded,
                color: AppColors.primaryDark, size: 26),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final dynamic batch;
  final bool isJoined;
  final VoidCallback onJoin;

  const _BatchCard(
      {required this.batch, required this.isJoined, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final bool active = batch['is_active'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: active ? AppColors.cardBg : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: active ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      batch['address'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: active ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  batch['status'] ?? 'Open',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoCol('DEPARTURE', batch['departure'] ?? '', active),
              const SizedBox(width: 32),
              _InfoCol('EST. ARRIVAL', batch['est_arrival'] ?? '', active),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('JOINED',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: active ? Colors.white54 : AppColors.textLight,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    '${batch['joined']}/${batch['size_limit']}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  _AvatarRow(count: (batch['joined'] as num).toInt()),
                ]),
              ]),
              const Spacer(),
              _InfoCol('SHARED FEE',
                  '₱${batch['shared_fee']?.toStringAsFixed(2)}', active),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: active ? onJoin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    active ? AppColors.primary : Colors.grey.shade200,
                disabledBackgroundColor: Colors.grey.shade200,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isJoined ? 'JOINED ✓' : 'JOIN KUMPRA',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primaryDark : AppColors.textLight,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label, value;
  final bool dark;
  const _InfoCol(this.label, this.value, this.dark);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: dark ? Colors.white54 : AppColors.textLight,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.textPrimary)),
        ],
      );
}

class _AvatarRow extends StatelessWidget {
  final int count;
  const _AvatarRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final show = count > 3 ? 2 : count;
    return Row(
      children: [
        for (int i = 0; i < show; i++)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey.shade400),
            child: const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        if (count > 3)
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.primary),
            child: Center(
                child: Text('+${count - 2}',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white))),
          ),
      ],
    );
  }
}
