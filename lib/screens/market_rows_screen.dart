import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/cart_provider.dart';

class MarketRowsScreen extends StatefulWidget {
  const MarketRowsScreen({super.key});

  @override
  State<MarketRowsScreen> createState() => _MarketRowsScreenState();
}

class _MarketRowsScreenState extends State<MarketRowsScreen> {
  String _activeRow = 'WET';

  final Map<String, List<Map<String, dynamic>>> _catalog = {
    'WET': [
      {'name': 'Bangus', 'emoji': '🐟', 'price_min': 210.0, 'price_max': 240.0, 'unit': 'kg'},
      {'name': 'Shrimp', 'emoji': '🦐', 'price_min': 480.0, 'price_max': 600.0, 'unit': 'kg'},
      {'name': 'Tilapia', 'emoji': '🐟', 'price_min': 120.0, 'price_max': 150.0, 'unit': 'kg'},
      {'name': 'Lucos', 'emoji': '🦑', 'price_min': 450.0, 'price_max': 460.0, 'unit': 'kg'},
      {'name': 'Tangigue', 'emoji': '🐡', 'price_min': 145.0, 'price_max': 180.0, 'unit': 'kg'},
      {'name': 'Galunggong', 'emoji': '🐠', 'price_min': 180.0, 'price_max': 200.0, 'unit': 'kg'},
    ],
    'MEAT': [
      {'name': 'Pork Liempo', 'emoji': '🥓', 'price_min': 350.0, 'price_max': 350.0, 'unit': 'kg'},
      {'name': 'Beef Lean Meat', 'emoji': '🐄', 'price_min': 370.0, 'price_max': 385.0, 'unit': 'kg'},
      {'name': 'Whole Chicken', 'emoji': '🐔', 'price_min': 180.0, 'price_max': 195.0, 'unit': 'kg'},
      {'name': 'Native Chicken', 'emoji': '🐓', 'price_min': 250.0, 'price_max': 300.0, 'unit': 'kg'},
      {'name': 'Pork Kasim', 'emoji': '🍖', 'price_min': 330.0, 'price_max': 340.0, 'unit': 'kg'},
    ],
    'VEG': [
      {'name': 'Onion', 'emoji': '🧅', 'price_min': 72.0, 'price_max': 72.0, 'unit': 'kg'},
      {'name': 'Tomatoes', 'emoji': '🍅', 'price_min': 98.0, 'price_max': 98.0, 'unit': 'kg'},
      {'name': 'Potatoes', 'emoji': '🥔', 'price_min': 180.0, 'price_max': 180.0, 'unit': 'kg'},
      {'name': 'Ginger', 'emoji': '🫚', 'price_min': 98.0, 'price_max': 98.0, 'unit': 'kg'},
      {'name': 'Garlic', 'emoji': '🧄', 'price_min': 150.0, 'price_max': 150.0, 'unit': 'kg'},
      {'name': 'Carrots', 'emoji': '🥕', 'price_min': 70.0, 'price_max': 70.0, 'unit': 'kg'},
      {'name': 'Siling Labuyo', 'emoji': '🌶️', 'price_min': 20.0, 'price_max': 20.0, 'unit': 'pack'},
    ],
    'SPICES': [
      {'name': 'Black Pepper', 'emoji': '🧂', 'price_min': 72.0, 'price_max': 72.0, 'unit': 'kg'},
      {'name': 'Atsuete', 'emoji': '🟠', 'price_min': 98.0, 'price_max': 98.0, 'unit': 'kg'},
      {'name': 'Laurel Leaves', 'emoji': '🌿', 'price_min': 180.0, 'price_max': 180.0, 'unit': 'kg'},
      {'name': 'Magic Sarap', 'emoji': '🧂', 'price_min': 98.0, 'price_max': 98.0, 'unit': 'pack'},
      {'name': 'Curry Powder', 'emoji': '🟡', 'price_min': 150.0, 'price_max': 150.0, 'unit': 'kg'},
      {'name': 'Salt', 'emoji': '🧂', 'price_min': 70.0, 'price_max': 70.0, 'unit': 'kg'},
    ],
  };

  final Map<String, String> _rowTitles = {
    'WET': 'Seafood & Shellfish',
    'MEAT': 'Fresh Meat & Poultry',
    'VEG': 'Fresh Produce Vegetables',
    'SPICES': 'Dried & Powdered Spices',
  };

  @override
  Widget build(BuildContext context) {
    final items = _catalog[_activeRow] ?? [];
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.primary,
          expandedHeight: 100,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              'Market Rows',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['WET', 'MEAT', 'VEG', 'SPICES'].map((row) {
                  final active = _activeRow == row;
                  return GestureDetector(
                    onTap: () => setState(() => _activeRow = row),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.primaryDark : AppColors.primary.withValues(alpha: 0.5)),
                      ),
      
    
                      child: Text(
                        row,
                        style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Text(
              _rowTitles[_activeRow] ?? '',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductCard(item: items[i]),
              childCount: items.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priceMin = item['price_min'] as double;
    final priceMax = item['price_max'] as double;
    final priceStr = priceMin == priceMax
        ? '₱${priceMin.toInt()}/${item['unit']}'
        : '₱${priceMin.toInt()}-${priceMax.toInt()}/${item['unit']}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.5))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item['emoji'], style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            item['name'],
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            priceStr,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAddModal(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size(0, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'ADD ITEM',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModal(BuildContext context, Map<String, dynamic> item) {
    double quantity = 1.0;
    String selectedUnit = 'KILO';
    final cart = context.read<CartProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(item['emoji'], style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['name'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                      selectedUnit == 'KILO'
                          ? '₱${(item['price_min'] as double).toInt()}-${(item['price_max'] as double).toInt()}/${item['unit']}'
                          : '₱${((item['price_min'] as double) / 2).toInt()}-${((item['price_max'] as double) / 2).toInt()}/${selectedUnit.toLowerCase()}',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              // Unit selector
              Row(
                children: ['KILO', 'PIECE', 'HALF'].map((u) => Expanded(
                  child: GestureDetector(
                    onTap: () => setModal(() {
                      selectedUnit = u;
                      if (quantity < 1.0) quantity = 1.0;
                      quantity = quantity.ceilToDouble();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedUnit == u ? AppColors.primaryDark : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(u, style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: selectedUnit == u ? Colors.white : AppColors.textSecondary,
                      ))),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              // Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QtyBtn(icon: Icons.remove, onTap: () {
                    if (quantity > 1.0) setModal(() => quantity -= 1.0);
                  }),
                  const SizedBox(width: 20),
                  Text(
                    quantity.toInt().toString(),
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 20),
                  _QtyBtn(icon: Icons.add, onTap: () => setModal(() => quantity += 1.0)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cart.addItem(CartItem(
                      name: item['name'],
                      emoji: item['emoji'],
                      pricePerUnit: selectedUnit == 'KILO'
                          ? item['price_min'] as double
                          : (item['price_min'] as double) / 2,
                      unit: selectedUnit.toLowerCase(),
                      quantity: quantity,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${item['name']} added to basket!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Text('ADD ITEM', style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark, letterSpacing: 1,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
      child: Icon(icon, size: 18),
    ),
  );
}
