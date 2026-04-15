import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final data = await ApiService.get('/admin/users', token: auth.token);
      final list = data is List ? data : (data['data'] as List? ?? []);
      setState(() { _users = list.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final isActive = user['is_active'] as bool? ?? true;
    final endpoint = isActive ? '/admin/users/${user['id']}/block' : '/admin/users/${user['id']}/unblock';
    try {
      await ApiService.put(endpoint, token: auth.token);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final q = _search.toLowerCase();
      return q.isEmpty || (u['email'] as String? ?? '').toLowerCase().contains(q) || (u['full_name'] as String? ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.green),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.green,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No users found', style: TextStyle(color: AppTheme.textMuted)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final u = filtered[i];
                              final isActive = u['is_active'] as bool? ?? true;
                              final isAdmin = u['is_admin'] as bool? ?? false;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: AppTheme.glassCard(radius: 16),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin ? AppTheme.gold : AppTheme.green,
                                    child: Text(
                                      ((u['full_name'] as String? ?? u['email'] as String? ?? 'U')[0]).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(u['full_name'] as String? ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      Row(children: [
                                        if (isAdmin) _badge('Admin', AppTheme.gold),
                                        if (!isActive) _badge('Blocked', Colors.red),
                                      ]),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'toggle') _toggleBlock(u);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(value: 'toggle', child: Row(children: [
                                        Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 18, color: isActive ? Colors.red : Colors.green),
                                        const SizedBox(width: 8),
                                        Text(isActive ? 'Block User' : 'Unblock User'),
                                      ])),
                                    ],
                                    icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
