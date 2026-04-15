import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  final Set<int> _productIds = {};

  Set<int> get productIds => _productIds;
  bool isWishlisted(int id) => _productIds.contains(id);

  Future<void> fetchWishlist(String token) async {
    try {
      final data = await ApiService.get('/users/wishlist', token: token);
      final list = data['data'] as List? ?? [];
      _productIds.clear();
      for (final item in list) {
        _productIds.add(item['product_id'] as int);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle(int productId, String token) async {
    if (_productIds.contains(productId)) {
      await ApiService.delete('/users/wishlist/$productId', token: token);
      _productIds.remove(productId);
    } else {
      await ApiService.post('/users/wishlist/$productId', token: token);
      _productIds.add(productId);
    }
    notifyListeners();
  }
}
