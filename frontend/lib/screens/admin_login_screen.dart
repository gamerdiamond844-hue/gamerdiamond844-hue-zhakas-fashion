import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _adminLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter email and password');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (result['is_admin'] == true || result['token_type'] == 'bearer') {
        if (mounted) Navigator.pushReplacementNamed(context, Routes.adminDashboard);
      } else {
        setState(() => _error = 'Not an admin account');
        await auth.logout();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.greenGold),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: AppTheme.gold, width: 2)),
                    child: const Icon(Icons.admin_panel_settings, size: 56, color: AppTheme.gold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Admin Panel', style: TextStyle(fontFamily: 'Georgia', fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('ZHAKAS FASHION — Owner Access', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)]),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Admin Email', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_error.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed: _loading ? null : _adminLogin,
                          child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Access Admin Panel'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← Back to Customer App', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
