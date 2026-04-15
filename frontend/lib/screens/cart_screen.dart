import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _applyingCoupon = false;
  String _couponError = '';
  String _couponSuccess = '';

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() { _applyingCoupon = true; _couponError = ''; _couponSuccess = ''; });
    try {
      final result = await ApiService.post(
        '/coupons/validate',
        body: {'code': code, 'order_value': cart.subtotal},
        token: auth.token,
      );
      final discount = (result['discount'] as num).toDouble();
      cart.applyCoupon(code, discount);
      setState(() => _couponSuccess = 'Coupon applied! You save ₹${discount.toStringAsFixed(0)}');
    } catch (e) {
      setState(() => _couponError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _applyingCoupon = false);
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart (${cart.itemCount})'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () { cart.clear(); },
              child: const Text('Clear', style: TextStyle(color: AppTheme.gold)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, Routes.home),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
                    child: const Text('Shop Now'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.glassCard(radius: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.product.images.isNotEmpty
                                    ? Image.network(item.product.images.first, width: 80, height: 80, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppTheme.background))
                                    : Container(width: 80, height: 80, color: AppTheme.background, child: const Icon(Icons.image_not_supported)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (item.selectedSize != null) Text('Size: ${item.selectedSize}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    if (item.selectedColor != null) Text('Color: ${item.selectedColor}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      _qtyBtn(Icons.remove, () => cart.updateQuantity(i, item.quantity - 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                      _qtyBtn(Icons.add, () => cart.updateQuantity(i, item.quantity + 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => cart.removeItem(i),
                                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coupon
                      if (cart.appliedCoupon == null) ...[
                        const Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon code',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD8CC))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _applyingCoupon ? null : _applyCoupon,
                              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
                              child: _applyingCoupon
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Apply'),
                            ),
                          ],
                        ),
                        if (_couponError.isNotEmpty) Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_couponError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                        if (_couponSuccess.isNotEmpty) Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_couponSuccess, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${cart.appliedCoupon} applied — Save ₹${cart.discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13))),
                              GestureDetector(onTap: () { cart.removeCoupon(); _couponCtrl.clear(); setState(() { _couponSuccess = ''; }); }, child: const Icon(Icons.close, color: Colors.green, size: 18)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _priceRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                      if (cart.discountAmount > 0) _priceRow('Coupon Discount', '-₹${cart.discountAmount.toStringAsFixed(0)}', color: Colors.green),
                      const SizedBox(height: 8),
                      _priceRow('Total', '₹${cart.total.toStringAsFixed(0)}', bold: true, large: true),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.placeOrder),
                        child: const Text('Proceed to Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFDDD8CC))),
        child: Icon(icon, size: 16, color: AppTheme.green),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false, bool large = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: large ? 17 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textDark)),
          Text(value, style: TextStyle(fontSize: large ? 17 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? (large ? AppTheme.green : AppTheme.textDark))),
        ],
      ),
    );
  }
}
