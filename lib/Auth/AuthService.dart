import 'package:http/http.dart' as http;
import 'dart:convert';

import 'TokenManager.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://13.124.128.228:5000/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];
      await TokenManager.saveToken(token);
      return true;
    } else {
      return false;
    }
  }
}