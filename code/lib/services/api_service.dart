import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl =
      'https://chronos-production-f584.up.railway.app/';

  static Future<Map<String, String>> get _headers async {
    // Aqui você pode adicionar headers como token de autenticação
    return {
      'Authorization': 'Bearer ${await _getToken()}',
      'Content-Type': 'application/json',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, dynamic data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, dynamic data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String endpoint, dynamic data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  }

  static Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await user.getIdToken();
      return token;
    }
    print('ProjectService: Usuário não autenticado.');
    return null;
  }
}
