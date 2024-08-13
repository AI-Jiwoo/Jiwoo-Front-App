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

  static Future<Map<String, dynamic>> analyzeMarketSize(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/market-research/market-size-growth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody)['data'];
    } else {
      throw Exception('Failed to analyze market size');
    }
  }


  static Future<Map<String, dynamic>> analyzeSimilarServices(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/market-research/similar-services-analysis'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to analyze similar services');
    }
  }

  static Future<Map<String, dynamic>> analyzeTrendCustomerTechnology(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/market-research/trend-customer-technology'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody)['data'];
    } else {
      throw Exception('Failed to analyze trend, customer, and technology');
    }
  }

  static Future<void> saveHistory(String token, Map<String, dynamic> historyData) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/market-research/save-history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(historyData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save history');
    }
  }
}

