import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import 'Api/MarketResearchAPI.dart';
import 'Auth/TokenManager.dart';


class MarketResearchPage extends StatefulWidget {
  @override
  _MarketResearchPageState createState() => _MarketResearchPageState();
}

class _MarketResearchPageState extends State<MarketResearchPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic>? _selectedBusiness;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _marketSizeGrowth;
  Map<String, dynamic>? _similarServices;
  Map<String, dynamic>? _trendCustomerTechnology;
  List<Map<String, dynamic>> _researchHistory = [];
  TabController? _tabController;
  List<String> _categories = [];
  Map<String, dynamic> _customData = {};

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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



  Widget _buildStepIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / 3,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepText(0, "사업 선택"),
            _buildStepText(1, "분석 유형 선택"),
            _buildStepText(2, "결과 확인"),
          ],
        ),
      ],
    );
  }

  Widget _buildStepText(int step, String text) {
    return Text(
      "${step + 1}. $text",
      style: TextStyle(
        fontWeight: _currentStep >= step ? FontWeight.bold : FontWeight.normal,
        color: _currentStep >= step ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBusinessSelection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.buildingUser, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('사업 선택 또는 정보 입력', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '사업 선택',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
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
                  if (value != null) {
                    _customData = Map.from(value);
                  } else {
                    _customData = {};
                  }
                });
              },
            ),
            if (_selectedBusiness == null) ...[
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '사업 분야 (카테고리)',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {
                    _customData['scale'] = value;
                  });
                },
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text('다음'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: (_selectedBusiness != null || _customData['category'] != null) ? () {
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
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.chartLine, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('분석 유형 선택', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildAnalysisButton('시장 규모 분석', FontAwesomeIcons.chartPie, 'marketSize'),
                _buildAnalysisButton('유사 서비스 분석', FontAwesomeIcons.users, 'similarServices'),
                _buildAnalysisButton('트렌드/고객/기술 분석', FontAwesomeIcons.lightbulb, 'trendCustomerTechnology'),
                ElevatedButton.icon(
                  icon: Icon(FontAwesomeIcons.list),
                  label: Text('전체 분석'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () => _analyzeMarket('all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisButton(String label, IconData icon, String type) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      onPressed: () => _analyzeMarket(type),
    );
  }

  Future<void> _analyzeMarket(String type) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('토큰이 없습니다. 다시 로그인해주세요.');
      }

      final data = _selectedBusiness ?? _customData;
      switch (type) {
        case 'marketSize':
          _marketSizeGrowth = await MarketResearchApi.analyzeMarketSize(token, data);
          break;
        case 'similarServices':
          _similarServices = await MarketResearchApi.analyzeSimilarServices(token, data);
          break;
        case 'trendCustomerTechnology':
          _trendCustomerTechnology = await MarketResearchApi.analyzeTrendCustomerTechnology(token, data);
          break;
        case 'all':
          final results = await Future.wait([
            MarketResearchApi.analyzeMarketSize(token, data),
            MarketResearchApi.analyzeSimilarServices(token, data),
            MarketResearchApi.analyzeTrendCustomerTechnology(token, data),
          ]);
          _marketSizeGrowth = results[0];
          _similarServices = results[1];
          _trendCustomerTechnology = results[2];
          break;
      }

      // Save research history
      await MarketResearchApi.saveHistory(token, {
        'createAt': DateTime.now().toIso8601String(),
        'marketInformation': jsonEncode(_marketSizeGrowth),
        'competitorAnalysis': jsonEncode(_similarServices),
        'marketTrends': jsonEncode(_trendCustomerTechnology),
        'businessId': _selectedBusiness?['id'] ?? -1,
      });

      setState(() {
        _currentStep = 2;
      });
    } catch (e) {
      setState(() {
        _error = '시장 분석에 실패했습니다: $e';
      });
      if (e.toString().contains('다시 로그인해주세요')) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResults() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_marketSizeGrowth != null) ...[
              Text('시장 규모 및 성장률', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              _buildMarketSizeGrowthChart(_marketSizeGrowth!),
            ],
            if (_similarServices != null) ...[
              Text('유사 서비스 분석', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              _buildSimilarServicesAnalysis(_similarServices!),
            ],
            if (_trendCustomerTechnology != null) ...[
              Text('트렌드, 고객 분포, 기술 동향', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              _buildTrendCustomerTechnologyAnalysis(_trendCustomerTechnology!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSizeGrowthChart(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 300,
          child: LineChart(
            LineChartData(
              // 차트 구성 (기존 코드 유지)
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          '시장 규모: ${data['marketSize'] ?? '데이터 없음'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 8),
        Text(
          '성장률: ${data['growthRate'] ?? '데이터 없음'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 16),
        Text(
          '상세 분석:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          data['analysis'] ?? '상세 분석 데이터가 없습니다.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSimilarServicesAnalysis(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['analysis'] ?? '분석 데이터가 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildTrendCustomerTechnologyAnalysis(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('트렌드:', style: Theme.of(context).textTheme.titleMedium),
        Text(data['trend'] ?? '데이터 없음', style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 8),
        Text('주요 고객:', style: Theme.of(context).textTheme.titleMedium),
        Text(data['mainCustomers'] ?? '데이터 없음', style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 8),
        Text('기술 동향:', style: Theme.of(context).textTheme.titleMedium),
        Text(data['technologyTrend'] ?? '데이터 없음', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildResearchHistory() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('조회 이력', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            if (_researchHistory.isEmpty)
              Text('조회 이력이 없습니다.', style: Theme.of(context).textTheme.bodyMedium)
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _researchHistory.length,
                itemBuilder: (context, index) {
                  final history = _researchHistory[index];
                  return ListTile(
                    title: Text(history['createAt'] ?? '날짜 없음'),
                    subtitle: Text('${history['businessName'] ?? '사업명 없음'}'),
                    onTap: () {
                      // Implement history detail view
                      _showHistoryDetail(history);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetail(Map<String, dynamic> history) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('조회 이력 상세'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('날짜: ${history['createAt'] ?? '날짜 없음'}'),
                Text('사업명: ${history['businessName'] ?? '사업명 없음'}'),
                SizedBox(height: 16),
                Text('시장 정보:', style: Theme.of(context).textTheme.titleMedium),
                Text(history['marketInformation'] ?? '정보 없음'),
                SizedBox(height: 8),
                Text('경쟁사 분석:', style: Theme.of(context).textTheme.titleMedium),
                Text(history['competitorAnalysis'] ?? '정보 없음'),
                SizedBox(height: 8),
                Text('시장 동향:', style: Theme.of(context).textTheme.titleMedium),
                Text(history['marketTrends'] ?? '정보 없음'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('닫기'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('시장 조사 도움말'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. 사업을 선택하거나 새로운 사업 정보를 입력하세요.'),
              Text('2. 원하는 분석 유형을 선택하세요.'),
              Text('3. 분석 결과를 확인하고 인사이트를 얻으세요.'),
              Text('문의사항이 있으면 고객 지원팀에 연락해주세요.'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('닫기'),
              onPressed: () => Navigator.of(context).pop(),
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
        title: Text('시장 조사💹'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(FontAwesomeIcons.circleQuestion),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: Theme.of(context).textTheme.bodyLarge))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildStepIndicator(),
            SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: '시장 분석'),
                Tab(text: '조회 이력'),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 600, // Adjust this height as needed
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Market Analysis Tab
                  Column(
                    children: [
                      if (_currentStep == 0) _buildBusinessSelection(),
                      if (_currentStep == 1) _buildAnalysisTypeSelection(),
                      if (_currentStep == 2) _buildResults(),
                    ],
                  ),
                  // History Tab
                  _buildResearchHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}