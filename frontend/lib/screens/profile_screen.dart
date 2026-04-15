import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;
    try {
      final userData = await ApiService.get('/users/me', token: auth.token);
      final ordersData = await ApiService.get('/orders/me', token: auth.token);
      final orderList = ordersData is List ? ordersData : (ordersData['data'] as List? ?? []);
      setState(() {
        _user = userData is Map<String, dynamic> ? userData : {};
        _orders = orderList.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppTheme.green,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(gradient: AppTheme.greenGold),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppTheme.gold,
                              backgroundImage: _user?['profile_image'] != null
                                  ? CachedNetworkImageProvider(_user!['profile_image'] as String)
                                  : null,
                              child: _user?['profile_image'] == null
                                  ? const Icon(Icons.person, size: 44, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(_user?['full_name'] ?? 'Customer', style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(_user?['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => _showEditDialog(),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        Row(
                          children: [
                            _statCard('Orders', '${_orders.length}', Icons.shopping_bag_outlined),
                            const SizedBox(width: 12),
                            _statCard('Pending', '${_orders.where((o) => o.status == 'pending').length}', Icons.hourglass_empty),
                            const SizedBox(width: 12),
                            _statCard('Approved', '${_orders.where((o) => o.status == 'approved').length}', Icons.check_circle_outline),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Quick actions
                        Container(
                          decoration: AppTheme.glassCard(),
                          child: Column(
                            children: [
                              _menuItem(Icons.favorite_border, 'My Wishlist', () => Navigator.pushNamed(context, Routes.wishlist)),
                              const Divider(height: 1, indent: 56),
                              _menuItem(Icons.local_offer_outlined, 'My Orders', () {}),
                              const Divider(height: 1, indent: 56),
                              _menuItem(Icons.notifications_outlined, 'Notifications', () {}),
                              const Divider(height: 1, indent: 56),
                              _menuItem(Icons.help_outline, 'Help & Support', () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Order History', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.green)),
                        const SizedBox(height: 12),
                        if (_orders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.glassCard(),
                            child: const Center(child: Text('No orders yet', style: TextStyle(color: AppTheme.textMuted))),
                          )
                        else
                          ...(_orders.map((o) => _orderCard(o))),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await auth.logout();
                            if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text('Logout', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.glassCard(radius: 16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.green, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.green)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.green),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }

  Widget _orderCard(Order o) {
    final statusColor = o.status == 'approved' ? Colors.green : o.status == 'rejected' ? Colors.red : Colors.orange;
    final statusIcon = o.status == 'approved' ? Icons.check_circle : o.status == 'rejected' ? Icons.cancel : Icons.hourglass_empty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('₹${o.totalAmount.toStringAsFixed(0)}${o.couponCode != null ? ' · Coupon: ${o.couponCode}' : ''}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(o.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _user?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Georgia', color: AppTheme.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              try {
                await ApiService.put('/users/me', token: auth.token, body: {'full_name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim()});
                Navigator.pop(context);
                _load();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
