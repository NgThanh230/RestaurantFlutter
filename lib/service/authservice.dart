import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://localhost:8080"; // Cập nhật IP backend

  // Đăng ký tài khoản
  Future<Map<String, dynamic>> register(String username, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    return jsonDecode(response.body);
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }
}
