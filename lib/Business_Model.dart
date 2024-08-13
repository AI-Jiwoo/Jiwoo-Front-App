import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Auth/TokenManager.dart';

class BusinessModelPage extends StatefulWidget {
  @override
  _BusinessModelPageState createState() => _BusinessModelPageState();
}

class _BusinessModelPageState extends State<BusinessModelPage> {
  int _currentStep = 1;
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;
  List<Map<String, dynamic>> _similarServices = [];
  Map<String, dynamic>? _analyzedBusinessModel;
  Map<String, dynamic>? _businessProposal;
  bool _isLoading = false;
  String? _error;
  List<String> _categories = [];
  Map<String, dynamic> _customData = {};

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
    _fetchCategories();
  }

  Future<void> _fetchBusinesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/business/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // UTF-8로 디코딩
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        setState(() {
          _businesses = List<Map<String, dynamic>>.from(data['business'] ?? []);
        });
      } else if (response.statusCode == 401) {
        await TokenManager.removeToken();
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load businesses: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = '사업 정보를 불러오는데 실패했습니다: $e';
      });
      print('Error fetching businesses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/category/names'),
        headers: {'Authorization': 'Bearer ${await _getToken()}'},
      );
      if (response.statusCode == 200) {
        setState(() => _categories = List<String>.from(json.decode(response.body)));
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load categories: $e');
    }
  }

  Future<String> _getToken() async {
    // TODO: Implement token retrieval logic
    return '';
  }

  Future<void> _getSimilarServices() async {
    if (_selectedBusiness == null && _customData['category'] == null) {
      setState(() => _error = '사업을 선택하거나 카테고리를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No token found');

      final data = _selectedBusiness ?? _customData;
      final response = await http.post(
        Uri.parse('http://localhost:5000/business-model/similar-services'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // UTF-8로 디코딩
        final decodedBody = utf8.decode(response.bodyBytes);
        setState(() {
          _similarServices = List<Map<String, dynamic>>.from(json.decode(decodedBody));
          _currentStep = 2;
        });
      } else if (response.statusCode == 401) {
        await TokenManager.removeToken();
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to get similar services: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '유사 서비스 조회에 실패했습니다: $e');
      print('Error getting similar services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeBusinessModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('http://localhost:5000/business-model/analyze'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(_similarServices),
      );

      if (response.statusCode == 200) {
        // UTF-8로 디코딩
        final decodedBody = utf8.decode(response.bodyBytes);
        setState(() {
          _analyzedBusinessModel = json.decode(decodedBody);
          _currentStep = 3;
        });
      } else if (response.statusCode == 401) {
        await TokenManager.removeToken();
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to analyze business models: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '비즈니스 모델 분석에 실패했습니다: $e');
      print('Error analyzing business models: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _proposeBusinessModel() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('http://localhost:5000/business-model/propose'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(_analyzedBusinessModel),
      );

      if (response.statusCode == 200) {
        // UTF-8로 디코딩
        final decodedBody = utf8.decode(response.bodyBytes);
        setState(() {
          _businessProposal = json.decode(decodedBody);
          _currentStep = 4;
        });
      } else if (response.statusCode == 401) {
        await TokenManager.removeToken();
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to propose business model: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '비즈니스 모델 제안에 실패했습니다: $e');
      print('Error proposing business model: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStepIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _currentStep / 4,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['사업 선택', '유사 서비스', '모델 분석', '모델 제안']
              .asMap()
              .entries
              .map((entry) => Text(
            '${entry.key + 1}. ${entry.value}',
            style: TextStyle(
              fontWeight: _currentStep >= entry.key + 1 ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBusinessSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사업 선택 또는 정보 입력', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '사업 선택',
              ),
              value: _selectedBusiness?['id'],
              items: _businesses.map((business) {
                return DropdownMenuItem<int>(
                  value: business['id'],
                  child: Text(business['businessName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusiness = _businesses.firstWhere((b) => b['id'] == value);
                });
              },
            ),
            if (_selectedBusiness == null) ...[
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '사업 분야 (카테고리)',
                ),
                value: _customData['category'],
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _customData['category'] = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '사업 규모',
                ),
                onChanged: (value) {
                  setState(() {
                    _customData['scale'] = value;
                  });
                },
              ),
              // Add more TextFormFields for other custom data fields
            ],
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('다음 단계'),
              onPressed: _getSimilarServices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarServices() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('유사 서비스', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            if (_similarServices.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: _similarServices.length,
                itemBuilder: (context, index) {
                  final service = _similarServices[index];
                  return ListTile(
                    title: Text(service['businessName'] ?? service['name'] ?? '이름 없음'),
                    subtitle: service['analysis'] != null ? Text(service['analysis']) : null,
                  );
                },
              )
            else
              Text('유사 서비스가 없습니다.'),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('비즈니스 모델 분석'),
              onPressed: _analyzeBusinessModels,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzedBusinessModel() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('비즈니스 모델 분석 결과', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Text(_analyzedBusinessModel?['analysis'] ?? ''),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('비즈니스 모델 제안'),
              onPressed: _proposeBusinessModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessProposal() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('비즈니스 모델 제안', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Text(_businessProposal?['proposal'] ?? ''),
          ],
        ),
      ),
    );
  }

  void _showFullResults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('전체 분석 결과'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('유사 서비스', style: Theme.of(context).textTheme.titleLarge),
                ..._similarServices.map((service) => ListTile(
                  title: Text(service['businessName'] ?? service['name'] ?? '이름 없음'),
                  subtitle: service['analysis'] != null ? Text(service['analysis']) : null,
                )),
                SizedBox(height: 16),
                Text('비즈니스 모델 분석 결과', style: Theme.of(context).textTheme.titleLarge),
                Text(_analyzedBusinessModel?['analysis'] ?? ''),
                SizedBox(height: 16),
                Text('비즈니스 모델 제안', style: Theme.of(context).textTheme.titleLarge),
                Text(_businessProposal?['proposal'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('비즈니스 모델👨‍💼'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(),
            SizedBox(height: 16),
            if (_error != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(_error!, style: TextStyle(color: Colors.red[900])),
                ),
              ),
            SizedBox(height: 16),
            if (_currentStep == 1) _buildBusinessSelection(),
            if (_currentStep == 2) _buildSimilarServices(),
            if (_currentStep == 3) _buildAnalyzedBusinessModel(),
            if (_currentStep == 4) _buildBusinessProposal(),
            if (_currentStep > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('새로운 분석 시작'),
                    onPressed: () {
                      setState(() {
                        _selectedBusiness = null;
                        _similarServices = [];
                        _analyzedBusinessModel = null;
                        _businessProposal = null;
                        _currentStep = 1;
                        _error = null;
                      });
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('전체 결과 보기'),
                    onPressed: _analyzedBusinessModel != null && _businessProposal != null
                        ? _showFullResults
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}