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
    // TODO: Implement market analysis logic
    print('Analyzing market: $type');
    // After analysis is complete:
    setState(() {
      _currentStep = 2;
    });
  }

  Widget _buildResults() {
    // TODO: Implement results display
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('분석 결과가 여기에 표시됩니다.'),
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