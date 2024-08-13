import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Api/MarketResearchAPI.dart';

class MarketResearchPage extends StatefulWidget {
  @override
  _MarketResearchPageState createState() => _MarketResearchPageState();
}

class _MarketResearchPageState extends State<MarketResearchPage> {
  int _currentStep = 0;
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _marketSizeGrowth;
  Map<String, dynamic>? _similarServices;
  Map<String, dynamic>? _trendCustomerTechnology;

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _businesses = await MarketResearchApi.fetchBusinesses();
    } catch (e) {
      setState(() {
        if (e.toString().contains('다시 로그인해주세요')) {
          _error = '세션이 만료되었습니다. 다시 로그인해주세요.';
          // 로그인 페이지로 리다이렉트
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          _error = '사업 정보를 불러오는데 실패했습니다: $e';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getToken() async {
    // TODO: Implement token retrieval logic
    return '';
  }

  Widget _buildBusinessSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사업 선택', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '사업 선택',
              ),
              value: _selectedBusiness,
              items: _businesses.map((business) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: business,
                  child: Text(business['businessName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusiness = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('다음'),
              onPressed: _selectedBusiness != null ? () {
                setState(() {
                  _currentStep = 1;
                });
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTypeSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('분석 유형 선택', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  child: Text('시장 규모 분석'),
                  onPressed: () => _analyzeMarket('marketSize'),
                ),
                ElevatedButton(
                  child: Text('유사 서비스 분석'),
                  onPressed: () => _analyzeMarket('similarServices'),
                ),
                ElevatedButton(
                  child: Text('트렌드/고객/기술 분석'),
                  onPressed: () => _analyzeMarket('trendCustomerTechnology'),
                ),
                ElevatedButton(
                  child: Text('전체 분석'),
                  onPressed: () => _analyzeMarket('all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeMarket(String type) async {
    if (_selectedBusiness == null) {
      setState(() {
        _error = '사업을 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final data = {
        'id': _selectedBusiness!['id'],
        'businessName': _selectedBusiness!['businessName'],
        'businessNumber': _selectedBusiness!['businessNumber'],
        'businessContent': _selectedBusiness!['businessContent'],
        'businessLocation': _selectedBusiness!['businessLocation'],
        'businessStartDate': _selectedBusiness!['businessStartDate'],
        'businessPlatform': _selectedBusiness!['businessPlatform'] ?? '',
        'businessScale': _selectedBusiness!['businessScale'] ?? '',
        'investmentStatus': _selectedBusiness!['investmentStatus'] ?? '',
        'customerType': _selectedBusiness!['customerType'] ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      switch (type) {
        case 'marketSize':
          final response = await MarketResearchApi.analyzeMarketSize(token, data);
          setState(() {
            _marketSizeGrowth = response;
          });
          break;
        case 'similarServices':
          final response = await MarketResearchApi.analyzeSimilarServices(token, data);
          setState(() {
            _similarServices = response;
          });
          break;
        case 'trendCustomerTechnology':
          final response = await MarketResearchApi.analyzeTrendCustomerTechnology(token, data);
          setState(() {
            _trendCustomerTechnology = response;
          });
          break;
        case 'all':
          final responses = await Future.wait([
            MarketResearchApi.analyzeMarketSize(token, data),
            MarketResearchApi.analyzeSimilarServices(token, data),
            MarketResearchApi.analyzeTrendCustomerTechnology(token, data),
          ]);
          setState(() {
            _marketSizeGrowth = responses[0];
            _similarServices = responses[1];
            _trendCustomerTechnology = responses[2];
          });
          break;
      }

      // 조회 이력 저장
      await MarketResearchApi.saveHistory(token, {
        'createAt': DateTime.now().toIso8601String(),
        'marketInformation': jsonEncode(_marketSizeGrowth),
        'competitorAnalysis': jsonEncode(_similarServices),
        'marketTrends': jsonEncode(_trendCustomerTechnology),
        'regulationInformation': '',
        'marketEntryStrategy': '',
        'businessId': _selectedBusiness!['id'],
      });

      setState(() {
        _currentStep = 2;
      });
    } catch (e) {
      setState(() {
        _error = '시장 분석에 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_marketSizeGrowth != null) ...[
              Text('시장 규모 및 성장률', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text('시장 규모: ${_marketSizeGrowth!['marketSize']}'),
              Text('성장률: ${_marketSizeGrowth!['growthRate']}'),
              SizedBox(height: 16),
            ],
            if (_similarServices != null) ...[
              Text('유사 서비스 분석', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text(_similarServices!['analysis']),
              SizedBox(height: 16),
            ],
            if (_trendCustomerTechnology != null) ...[
              Text('트렌드, 고객 분포, 기술 동향', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text('트렌드: ${_trendCustomerTechnology!['trend']}'),
              Text('주요 고객: ${_trendCustomerTechnology!['mainCustomers']}'),
              Text('기술 동향: ${_trendCustomerTechnology!['technologyTrend']}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('시장 조사'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              steps: [
                Step(
                  title: Text('사업 선택'),
                  content: _buildBusinessSelection(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: Text('분석 유형 선택'),
                  content: _buildAnalysisTypeSelection(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: Text('결과'),
                  content: _buildResults(),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}