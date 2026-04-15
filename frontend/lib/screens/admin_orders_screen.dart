import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({String? status}) async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final data = await ApiService.get('/admin/orders', token: auth.token, query: status != null ? {'status': status} : null);
      final list = data is List ? data : (data['data'] as List? ?? []);
      setState(() {
        _orders = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await ApiService.put('/orders/$orderId/status', body: {'status': status}, token: auth.token);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order #$orderId $status'),
        backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  List<Map<String, dynamic>> _filtered(String status) {
    if (status == 'all') return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          onTap: (i) {
            final statuses = ['pending', 'approved', 'rejected'];
            _load(status: statuses[i]);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : TabBarView(
              controller: _tabs,
              children: ['pending', 'approved', 'rejected'].map((s) => _orderList(_filtered(s), s)).toList(),
            ),
    );
  }

  Widget _orderList(List<Map<String, dynamic>> orders, String status) {
    if (orders.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No $status orders', style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i]),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = o['status'] as String;
    final statusColor = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassCard(radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, o['shipping_name'] ?? ''),
            _infoRow(Icons.phone_outlined, o['shipping_phone'] ?? ''),
            _infoRow(Icons.location_on_outlined, o['shipping_address'] ?? ''),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 16, color: AppTheme.green),
                Text('${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.green, fontSize: 15)),
                if (o['coupon_code'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${o['coupon_code']} -₹${o['discount_amount']}', style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            if (o['payment_proof'] != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showProof(o['payment_proof'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.image_outlined, color: AppTheme.green, size: 16),
                    SizedBox(width: 6),
                    Text('View Payment Proof', style: TextStyle(color: AppTheme.green, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(o['id'] as int, 'approved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(0, 40)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(o['id'] as int, 'rejected'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(0, 40)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  void _showProof(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(20), child: Text('Could not load image'))),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
