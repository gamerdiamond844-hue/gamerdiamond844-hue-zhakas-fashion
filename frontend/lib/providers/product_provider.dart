import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  List<Product> get trending => _products.where((p) => p.isTrending).toList();
  List<Product> get featured => _products.where((p) => p.isFeatured).toList();

  Future<void> fetchProducts({String? token}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.get('/products/', token: token);
      final list = data['data'] as List? ?? (data.containsKey('id') ? [data] : []);
      _products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
