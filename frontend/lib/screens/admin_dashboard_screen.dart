import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final data = await ApiService.get('/admin/dashboard', token: auth.token);
      setState(() { _stats = data is Map<String, dynamic> ? data : {}; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.gold),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.greenCard(),
                      child: Row(
                        children: [
                          const Icon(Icons.diamond_outlined, color: AppTheme.gold, size: 36),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ZHAKAS FASHION', style: TextStyle(fontFamily: 'Georgia', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Admin Control Panel', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _statCard('Total Users', '${_stats['total_users'] ?? 0}', Icons.people_outline, AppTheme.green),
                        _statCard('Total Orders', '${_stats['total_orders'] ?? 0}', Icons.receipt_long_outlined, Colors.blue),
                        _statCard('Pending', '${_stats['pending_orders'] ?? 0}', Icons.hourglass_empty, Colors.orange),
                        _statCard('Revenue', '₹${_formatRevenue(_stats['revenue'])}', Icons.currency_rupee, AppTheme.gold),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Revenue chart
                    const Text('Sales Overview', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.green)),
                    const SizedBox(height: 14),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCard(),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barGroups: List.generate(7, (i) => BarChartGroupData(
                            x: i,
                            barRods: [BarChartRodData(
                              toY: [40, 65, 50, 80, 55, 90, 70][i].toDouble(),
                              color: AppTheme.green,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                            )],
                          )),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt()], style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)))),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Navigation
                    const Text('Manage', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.green)),
                    const SizedBox(height: 14),
                    Container(
                      decoration: AppTheme.glassCard(),
                      child: Column(
                        children: [
                          _navTile(Icons.inventory_2_outlined, 'Products', 'Add, edit, delete products', Routes.adminProducts),
                          const Divider(height: 1, indent: 56),
                          _navTile(Icons.receipt_long_outlined, 'Orders', 'Approve or reject orders', Routes.adminOrders),
                          const Divider(height: 1, indent: 56),
                          _navTile(Icons.local_offer_outlined, 'Coupons', 'Create and manage coupons', Routes.adminCoupons),
                          const Divider(height: 1, indent: 56),
                          _navTile(Icons.people_outline, 'Users', 'View and manage users', Routes.adminUsers),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _navTile(IconData icon, String title, String subtitle, String route) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.green, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  String _formatRevenue(dynamic val) {
    if (val == null) return '0';
    final d = (val as num).toDouble();
    if (d >= 100000) return '${(d / 100000).toStringAsFixed(1)}L';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    return d.toStringAsFixed(0);
  }
}
