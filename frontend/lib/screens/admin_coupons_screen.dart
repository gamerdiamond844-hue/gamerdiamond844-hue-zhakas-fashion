import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/coupon.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final data = await ApiService.get('/coupons/', token: auth.token);
      final list = data is List ? data : (data['data'] as List? ?? []);
      setState(() { _coupons = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete('/coupons/$id', token: auth.token);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> coupon) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await ApiService.put('/coupons/${coupon['id']}', token: auth.token, body: {
        ...coupon,
        'is_active': !(coupon['is_active'] as bool),
      });
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showForm({Map<String, dynamic>? coupon}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponFormSheet(coupon: coupon, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.gold,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.green,
              child: _coupons.isEmpty
                  ? const Center(child: Text('No coupons yet', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _coupons.length,
                      itemBuilder: (_, i) => _couponCard(_coupons[i]),
                    ),
            ),
    );
  }

  Widget _couponCard(Map<String, dynamic> c) {
    final isActive = c['is_active'] as bool? ?? false;
    final expiry = c['expiry_date'] != null ? DateTime.tryParse(c['expiry_date'] as String) : null;
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final discountType = c['discount_type'] as String? ?? 'percentage';
    final discountValue = (c['discount_value'] as num?)?.toDouble() ?? 0;
    final discountLabel = discountType == 'percentage' ? '${discountValue.toStringAsFixed(0)}% OFF' : '₹${discountValue.toStringAsFixed(0)} OFF';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassCard(radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_offer, color: AppTheme.gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['code'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark, letterSpacing: 1)),
                      Text(discountLabel, style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Switch(value: isActive && !isExpired, onChanged: (_) => _toggleActive(c), activeColor: AppTheme.green),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('Min ₹${(c['minimum_order_value'] as num?)?.toStringAsFixed(0) ?? '0'}', Icons.shopping_cart_outlined),
                _chip('Used: ${c['total_used'] ?? 0}/${c['usage_limit'] ?? '∞'}', Icons.people_outline),
                if (expiry != null) _chip(isExpired ? 'Expired' : 'Expires ${DateFormat('dd MMM yy').format(expiry)}', Icons.calendar_today_outlined, color: isExpired ? Colors.red : null),
                if (c['first_time_user'] == true) _chip('First-time only', Icons.star_outline, color: AppTheme.gold),
                _chip(c['applicable_to'] as String? ?? 'all', Icons.category_outlined),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showForm(coupon: c),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(c['id'] as int),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), minimumSize: const Size(0, 38)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (color ?? AppTheme.textMuted).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color ?? AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color ?? AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _CouponFormSheet extends StatefulWidget {
  final Map<String, dynamic>? coupon;
  final VoidCallback onSaved;
  const _CouponFormSheet({this.coupon, required this.onSaved});

  @override
  State<_CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<_CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _codeCtrl = TextEditingController(text: widget.coupon?['code'] ?? '');
  late final _valueCtrl = TextEditingController(text: widget.coupon?['discount_value']?.toString() ?? '');
  late final _minCtrl = TextEditingController(text: widget.coupon?['minimum_order_value']?.toString() ?? '0');
  late final _maxCtrl = TextEditingController(text: widget.coupon?['maximum_discount']?.toString() ?? '');
  late final _limitCtrl = TextEditingController(text: widget.coupon?['usage_limit']?.toString() ?? '0');
  late final _perUserCtrl = TextEditingController(text: widget.coupon?['per_user_limit']?.toString() ?? '1');
  late String _type = widget.coupon?['discount_type'] ?? 'percentage';
  late String _applicable = widget.coupon?['applicable_to'] ?? 'all';
  late bool _firstTime = widget.coupon?['first_time_user'] ?? false;
  DateTime _expiry = widget.coupon?['expiry_date'] != null
      ? DateTime.tryParse(widget.coupon!['expiry_date'] as String) ?? DateTime.now().add(const Duration(days: 30))
      : DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  void _autoGenCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(8, (i) => chars[(DateTime.now().millisecondsSinceEpoch + i * 7) % chars.length]).join();
    _codeCtrl.text = code;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final body = {
      'code': _codeCtrl.text.trim().toUpperCase(),
      'discount_type': _type,
      'discount_value': double.tryParse(_valueCtrl.text) ?? 0,
      'minimum_order_value': double.tryParse(_minCtrl.text) ?? 0,
      'maximum_discount': _maxCtrl.text.isNotEmpty ? double.tryParse(_maxCtrl.text) : null,
      'expiry_date': _expiry.toIso8601String(),
      'usage_limit': int.tryParse(_limitCtrl.text) ?? 0,
      'per_user_limit': int.tryParse(_perUserCtrl.text) ?? 1,
      'applicable_to': _applicable,
      'first_time_user': _firstTime,
      'is_active': true,
      'product_ids': [],
    };
    try {
      if (widget.coupon != null) {
        await ApiService.put('/coupons/${widget.coupon!['id']}', body: body, token: auth.token);
      } else {
        await ApiService.post('/coupons/', body: body, token: auth.token);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.coupon != null ? 'Edit Coupon' : 'Create Coupon', style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.green)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'Coupon Code'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _autoGenCode,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 52)),
                          child: const Text('Auto'),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Discount Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _typeBtn('percentage', '% Percentage')),
                        const SizedBox(width: 10),
                        Expanded(child: _typeBtn('flat', '₹ Flat Amount')),
                      ]),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: _type == 'percentage' ? 'Discount %' : 'Discount Amount (₹)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Order (₹)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Discount (₹)'))),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Usage Limit'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _perUserCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Per User Limit'))),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Applicable On', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: ['all', 'saree', 'lehenga'].map((a) => ChoiceChip(
                        label: Text(a.toUpperCase()),
                        selected: _applicable == a,
                        onSelected: (_) => setState(() => _applicable = a),
                        selectedColor: AppTheme.green,
                        labelStyle: TextStyle(color: _applicable == a ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w600),
                      )).toList()),
                      const SizedBox(height: 14),
                      // Expiry date
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiry,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                            builder: (_, child) => Theme(data: ThemeData(colorScheme: const ColorScheme.light(primary: AppTheme.green)), child: child!),
                          );
                          if (picked != null) setState(() => _expiry = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDDD8CC))),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined, color: AppTheme.green, size: 20),
                            const SizedBox(width: 10),
                            Text('Expires: ${DateFormat('dd MMM yyyy').format(_expiry)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _firstTime,
                        onChanged: (v) => setState(() => _firstTime = v),
                        title: const Text('First-time users only'),
                        activeColor: AppTheme.green,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.coupon != null ? 'Update Coupon' : 'Create Coupon'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String value, String label) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.green : const Color(0xFFDDD8CC), width: 1.5),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w600))),
      ),
    );
  }
}
