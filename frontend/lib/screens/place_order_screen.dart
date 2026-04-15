import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _proofUrl;
  bool _uploadingProof = false;
  int _step = 0; // 0=details, 1=payment, 2=confirm

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    setState(() => _uploadingProof = true);
    try {
      final bytes = await file.readAsBytes();
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await ApiService.uploadFile('/products/upload-media', bytes, file.name, token: auth.token);
      setState(() => _proofUrl = result['url'] as String?);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _uploadingProof = false);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final items = cart.items.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
        'size': i.selectedSize,
        'color': i.selectedColor,
        'price': i.product.price - i.product.discount,
      }).toList();

      await ApiService.post('/orders/', token: auth.token, body: {
        'shipping_name': _nameCtrl.text.trim(),
        'shipping_address': _addressCtrl.text.trim(),
        'shipping_phone': _phoneCtrl.text.trim(),
        'payment_proof': _proofUrl,
        'coupon_code': cart.appliedCoupon,
        'discount_amount': cart.discountAmount,
        'total_amount': cart.total,
        'items': items,
      });

      cart.clear();
      if (mounted) {
        setState(() => _step = 2);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 2) return _buildSuccess();
    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            if (_formKey.currentState!.validate()) setState(() => _step = 1);
          } else if (_step == 1) {
            _placeOrder();
          }
        },
        onStepCancel: () { if (_step > 0) setState(() => _step--); },
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _loading ? null : details.onStepContinue,
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_step == 1 ? 'Place Order' : 'Continue'),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(100, 48)),
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Shipping Details'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => (v == null || v.length < 10) ? 'Enter valid phone' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<CartProvider>(
                  builder: (_, cart, __) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      children: [
                        _row('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                        if (cart.discountAmount > 0) _row('Discount', '-₹${cart.discountAmount.toStringAsFixed(0)}', color: Colors.green),
                        const Divider(height: 16),
                        _row('Total Payable', '₹${cart.total.toStringAsFixed(0)}', bold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Scan QR to Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.gold, width: 2),
                      boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.2), blurRadius: 16)],
                    ),
                    child: Column(
                      children: [
                        Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=zhakasfashion@upi&pn=ZHAKAS+FASHION',
                          width: 180,
                          height: 180,
                          errorBuilder: (_, __, ___) => Container(
                            width: 180,
                            height: 180,
                            color: AppTheme.background,
                            child: const Center(child: Text('UPI: zhakasfashion@upi', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('UPI: zhakasfashion@upi', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.green)),
                        const Text('ZHAKAS FASHION', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Upload Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _uploadingProof ? null : _pickAndUploadProof,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _proofUrl != null ? AppTheme.green : const Color(0xFFDDD8CC), width: 1.5, style: BorderStyle.solid),
                    ),
                    child: _uploadingProof
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
                        : _proofUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.network(_proofUrl!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, color: AppTheme.green, size: 32),
                                  SizedBox(height: 6),
                                  Text('Tap to upload screenshot', style: TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                  ),
                ),
                if (_proofUrl != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: const [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 6), Text('Screenshot uploaded', style: TextStyle(color: Colors.green, fontSize: 13))]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.greenGold),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: AppTheme.green, size: 72),
                ),
                const SizedBox(height: 28),
                const Text('Order Placed!', style: TextStyle(fontFamily: 'Georgia', fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Your order is pending admin approval.\nYou will be notified once approved.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, minimumSize: const Size(200, 52)),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.profile),
                  child: const Text('View Orders', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color ?? AppTheme.textDark, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
