import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  bool _sending = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<String?> _getJoinedBatchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('joined_batch_id');
  }

  Future<bool> _shouldShowLeaveBatch() async {
    final prefs = await SharedPreferences.getInstance();
    final batchId = prefs.getString('joined_batch_id');
    final orderId = prefs.getInt('current_order_id');
    return batchId != null && batchId.isNotEmpty && orderId == null;
  }

  Future<void> _leaveBatch() async {
    final batchId = await _getJoinedBatchId();
    final requestBody = <String, dynamic>{};
    if (batchId != null && batchId.isNotEmpty) {
      requestBody['batch_id'] = int.parse(batchId);
    }

    setState(() => _leaving = true);

    final res = await ApiService.post(
      'batches/leave.php',
      requestBody,
      auth: true,
    );
    
    if (!mounted) return;

    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('joined_batch_id');
      await prefs.remove('current_order_id');
      
      if (mounted) {
        final cart = context.read<CartProvider>();
        cart.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You left the batch. Your cart has been cleared.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed to leave batch. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }

    if (mounted) {
      setState(() => _leaving = false);
    }
  }

  void _sendToRider(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add items to your basket first!'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final batchId = prefs.getString('joined_batch_id');
    if (batchId == null || batchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Join or create a batch before sending your order.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _sending = true);
    final items = cart.items
        .map((i) => {
              'item_name': i.name,
              'quantity': '${i.quantity} ${i.unit}',
              'user_est_price': i.pricePerUnit,
              'weight_kg': i.quantity,
            })
        .toList();

    final res = await ApiService.post(
        'orders/create.php',
        {
          'batch_id': int.parse(batchId),
          'estimated_total': cart.total,
          'items': items,
        },
        auth: true);

    if (mounted) {
      setState(() => _sending = false);
    }

    // FIX: Removed `|| true` which short-circuited the real API result,
    //      causing the app to always show "success" even on network/server errors.
    if (res['success'] == true) {
      final orderId = res['order_id'];
      if (orderId != null) {
        final prefs = await SharedPreferences.getInstance();
        final orderIdInt = orderId is int ? orderId : int.tryParse(orderId.toString());
        if (orderIdInt != null) {
          await prefs.setInt('current_order_id', orderIdInt);
        }
      }
      cart.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order sent to rider! Track your order.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(res['message'] ?? 'Failed to send order. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'YOUR BASKET',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            letterSpacing: 1,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? _emptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'ITEMS TO BE PICKED',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...cart.items.map((item) => _BasketItem(item: item)),
                      const SizedBox(height: 24),
                      _SummaryCard(cart: cart),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : () => _sendToRider(cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _sending
                              ? const CircularProgressIndicator(
                                  color: AppColors.primaryDark, strokeWidth: 2)
                              : Text(
                                  'SEND TO RIDER',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _leaving ? null : _leaveBatch,
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text(
                            'LEAVE BATCH',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState() => FutureBuilder<bool>(
        future: _shouldShowLeaveBatch(),
        builder: (context, snapshot) {
          final showLeaveButton = snapshot.data == true;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_outlined,
                    size: 72, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text('Your basket is empty',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Join a batch and add items from the Market Rows',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textLight),
                    textAlign: TextAlign.center),
                if (showLeaveButton) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: OutlinedButton.icon(
                      onPressed: _leaving ? null : _leaveBatch,
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text('Leave Batch',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _BasketItem extends StatelessWidget {
  final CartItem item;
  const _BasketItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              Text(
                '${item.quantity.toStringAsFixed(1)} ${item.unit.toUpperCase()} • ₱${item.total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ]),
          ),
          GestureDetector(
            onTap: () => context.read<CartProvider>().removeItem(item.name),
            child:
                const Icon(Icons.close, color: AppColors.textLight, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CartProvider cart;
  const _SummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        _Row('ESTIMATED TOTAL', '₱${cart.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _Row('DELIVERY FEE', '₱${cart.deliveryFee.toStringAsFixed(2)}'),
        const Divider(height: 24),
        _Row('TOTAL', '₱${cart.total.toStringAsFixed(2)}', bold: true),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.primaryDark,
              )),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.primaryDark,
              )),
        ],
      );
}
