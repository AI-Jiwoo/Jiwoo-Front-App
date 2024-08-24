import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Auth/TokenManager.dart';

class MarketResearchApi {
  static const String baseUrl = 'http://13.124.128.228:5000';

  static Future<List<Map<String, dynamic>>> fetchBusinesses() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/business/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept-Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(data['business'] ?? []);
    } else if (response.statusCode == 401) {
      await TokenManager.removeToken();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    } else {
      throw Exception('Failed to load businesses: ${response.statusCode}');
    }
  }

  static Future<dynamic> analyzeMarketSize(Map<String, dynamic> data) async {
    return _makeApiCall('$baseUrl/market-research/market-size-growth', data);
  }

  static Future<dynamic> analyzeSimilarServices(Map<String, dynamic> data) async {
    return _makeApiCall('$baseUrl/market-research/similar-services-analysis', data);
  }

  static Future<dynamic> analyzeTrendCustomerTechnology(Map<String, dynamic> data) async {
    return _makeApiCall('$baseUrl/market-research/trend-customer-technology', data);
  }

  static Future<String> saveHistory(Map<String, dynamic> historyData) async {
    final result = await _makeApiCall('$baseUrl/market-research/save-history', historyData, expectJson: false);
    return result as String;
  }

  static Future<List<String>> fetchCategories() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/category/names'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept-Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.cast<String>();
    } else if (response.statusCode == 401) {
      await TokenManager.removeToken();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    } else {
      throw Exception('카테고리 목록을 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }

  static Future<dynamic> _makeApiCall(String url, Map<String, dynamic> data, {bool expectJson = true}) async {
    final token = await _getToken();
    try {
      print('Sending data to $url: ${jsonEncode(data)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (expectJson) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final responseData = jsonDecode(decodedBody);
          if (responseData.containsKey('data')) {
            return responseData['data'];
          } else {
            return responseData;
          }
        } else {
          return utf8.decode(response.bodyBytes);
        }
      } else {
        final decodedError = utf8.decode(response.bodyBytes);
        throw Exception('API 호출 실패: ${response.statusCode} - $decodedError');
      }
    } catch (e) {
      print('Error in API call: $e');
      rethrow;
    }
  }

  static Future<String> _getToken() async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }
}