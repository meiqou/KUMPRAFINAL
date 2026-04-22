import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      if (!mounted) return;
      setState(() => _loading = true);
      final res = await ApiService.get('orders/history.php', auth: true);
      if (mounted) {
        if (res['success'] == true) {
          setState(() => _orders = List.from(res['orders'] ?? []));
        } else {
          setState(() => _error = res['message'] ?? 'Failed to load');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Delivery History', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.history_toggle_off, size: 64, color: AppColors.textSecondary),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(_error, style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loadHistory,
                                  child: const Text('Retry'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _orders.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long, size: 80, color: AppColors.textSecondary),
                                  const SizedBox(height: 16),
                                  Text('No orders yet', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                                    child: Text('Your delivery history will appear here once you place your first order', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary), textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withAlpha(25),
                                child: const Icon(Icons.receipt, color: AppColors.primary, size: 24),
                              ),
                              title: Text(
                                order['batch_name'] ?? 'Order #${order['order_id']}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['date'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Total: ₱${(order['total'] ?? 0).toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  order['status'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: _statusColor((order['status'] ?? '').toLowerCase()),
                              ),
                              onTap: () {},
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'pending':
      case 'gathering':
        return Colors.orange;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}

