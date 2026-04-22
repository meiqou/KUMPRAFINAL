import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import 'live_map_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _openLiveMap() async {
    final order = _order;
    if (order == null) return;

    final orderId = _toInt(order['order_id']);
    final lat = _toDouble(order['rider_latitude'] ?? order['latitude']);
    final lng = _toDouble(order['rider_longitude'] ?? order['longitude']);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMapScreen(
          orderId: orderId,
          latitude: lat ?? AppConstants.marketLat,
          longitude: lng ?? AppConstants.marketLng,
          isLiveLocation: lat != null && lng != null,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> refreshOrder() async {
    setState(() => _loading = true);
    await _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getInt('current_order_id');

    if (orderId == null) {
      setState(() => _loading = false);
      return;
    }

    final res = await ApiService.get(
      'orders/status.php',
      auth: true,
      params: {'order_id': orderId.toString()},
    );

    if (res['success'] == true && res['order'] != null) {
      setState(() => _order = res['order']);
    }
    setState(() => _loading = false);
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('No active orders yet', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final batchStatus = order['batch_status'] ?? 'Gathering';
    final progressMap = {'Gathering': 0.0, 'Last_Call': 0.0, 'Locked': 0.0, 'Purchasing': 0.25, 'In_Transit': 0.75, 'Completed': 1.0};
    final progress = progressMap[batchStatus] ?? 0.0;
    final batchName = '${order['barangay_name'] ?? 'BATCH'}-${order['batch_id'] ?? ''}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER IN PROGRESS', style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: 1,
                  )),
                  Text(batchName.toUpperCase(), style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic,
                  )),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Rider Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                        child: const Icon(Icons.person, size: 28, color: Colors.grey),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(order['rider_name'] ?? 'Unassigned', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('ASSIGNED RIDER', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight, letterSpacing: 1)),
                      ]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('MARKET PROGRESS', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 10),
                _ProgressBar(progress: progress),
                const SizedBox(height: 20),
                if (items.isNotEmpty) ...[
                  Text('PICKED ITEMS', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ...items.asMap().entries.map((e) {
                    final item = e.value as Map<String, dynamic>;
                    final itemName = item['item_name'] ?? 'Item';
                    final quantity = item['quantity'] ?? '1 unit';
                    final price = '₱${(item['user_est_price'] ?? 0).toStringAsFixed(2)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _itemCard('📦', itemName, quantity, price),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('ESTIMATED TOTAL', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        Text('₱${(order['estimated_total'] ?? 0).toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      ]),
                      const Spacer(),
                      Text('Delivery Fee Included', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openLiveMap,
                  icon: const Icon(Icons.map_outlined, color: AppColors.primaryDark),
                  label: Text('VIEW LIVE MAP', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(String emoji, String name, String qty, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          Text('$qty • $price', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final steps = ['GATHERING', 'PURCHASING', 'IN_TRANSIT', 'COMPLETED'];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) => Text(s, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.w600))).toList(),
        ),
      ],
    );
  }
}
