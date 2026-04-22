import 'package:flutter/foundation.dart';

class CartItem {
  final String name;
  final String emoji;
  final double pricePerUnit;
  final String unit;
  double quantity;

  CartItem({
    required this.name,
    required this.emoji,
    required this.pricePerUnit,
    required this.unit,
    required this.quantity,
  });

  double get total => pricePerUnit * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get deliveryFee => 25.0;
  double get total => subtotal + deliveryFee;

  void addItem(CartItem item) {
    final existing = _items.indexWhere((i) => i.name == item.name);
    if (existing >= 0) {
      _items[existing].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int get count => _items.length;
}
