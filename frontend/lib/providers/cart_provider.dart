import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _appliedCoupon;
  double _discountAmount = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get appliedCoupon => _appliedCoupon;
  double get discountAmount => _discountAmount;

  double get subtotal => _items.fold(0, (sum, i) => sum + i.totalPrice);
  double get total => (subtotal - _discountAmount).clamp(0, double.infinity);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  void addItem(Product product, {String? size, String? color}) {
    final idx = _items.indexWhere(
      (i) => i.product.id == product.id && i.selectedSize == size && i.selectedColor == color,
    );
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product, selectedSize: size, selectedColor: color));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = qty;
    }
    notifyListeners();
  }

  void applyCoupon(String code, double discount) {
    _appliedCoupon = code;
    _discountAmount = discount;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _appliedCoupon = null;
    _discountAmount = 0;
    notifyListeners();
  }
}
