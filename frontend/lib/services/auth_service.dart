import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?['is_admin'] == true;

  Future<bool> loadToken() async {
    _token = await _storage.read(key: 'access_token');
    final userJson = await _storage.read(key: 'user_data');
    if (userJson != null) _user = jsonDecode(userJson) as Map<String, dynamic>;
    notifyListeners();
    return isAuthenticated;
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'user_data', value: jsonEncode(user));
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final accessToken = body['access_token'] as String?;
      if (accessToken != null) {
        // Fetch user profile to get is_admin
        final userResp = await http.get(
          Uri.parse('${ApiService.baseUrl}/users/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        final userData = userResp.statusCode == 200
            ? jsonDecode(userResp.body) as Map<String, dynamic>
            : <String, dynamic>{};
        await _saveSession(accessToken, userData);
        return {...body, ...userData};
      }
      return body;
    }
    throw Exception(body['detail'] ?? 'Login failed ${response.statusCode}');
  }

  Future<Map<String, dynamic>> signup(String email, String password, String fullName) async {
    return await ApiService.post('/auth/signup', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
    }) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
