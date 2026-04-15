import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static Map<String, String> _headers({String? token, bool form = false}) => {
    'Content-Type': form ? 'application/x-www-form-urlencoded' : 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static dynamic _parse(http.Response r) {
    final body = r.body.isEmpty ? '{}' : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw Exception((body is Map ? body['detail'] : null) ?? 'Error ${r.statusCode}');
  }

  static Future<dynamic> get(String path, {String? token, Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _parse(await http.get(uri, headers: _headers(token: token)));
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body, String? token}) async {
    return _parse(await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token: token),
      body: jsonEncode(body ?? {}),
    ));
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body, String? token}) async {
    return _parse(await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token: token),
      body: jsonEncode(body ?? {}),
    ));
  }

  static Future<dynamic> delete(String path, {String? token}) async {
    return _parse(await http.delete(Uri.parse('$baseUrl$path'), headers: _headers(token: token)));
  }

  static Future<dynamic> postForm(String path, Map<String, String> fields) async {
    return _parse(await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(form: true),
      body: fields,
    ));
  }

  static Future<dynamic> uploadFile(String path, List<int> bytes, String filename, {String? token}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    return _parse(resp);
  }
}
