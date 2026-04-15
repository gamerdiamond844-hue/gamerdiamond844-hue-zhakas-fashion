import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? selectedSize;
  String? selectedColor;

  CartItem({required this.product, this.quantity = 1, this.selectedSize, this.selectedColor});

  double get totalPrice => (product.price - product.discount) * quantity;
}
