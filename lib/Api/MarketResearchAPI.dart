import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Auth/TokenManager.dart';

class MarketResearchApi {
  static Future<List<Map<String, dynamic>>> fetchBusinesses() async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('토큰이 없습니다. 다시 로그인해주세요.');
    }

    final response = await http.get(
      Uri.parse('http://localhost:5000/business/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept-Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(data['business'] ?? []);
    } else if (response.statusCode == 401) {
      // 토큰이 만료되었거나 유효하지 않은 경우
      await TokenManager.removeToken();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    } else {
      throw Exception('Failed to load businesses: ${response.statusCode}');
    }
  }
}