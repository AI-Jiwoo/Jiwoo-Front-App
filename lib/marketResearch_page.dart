import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'Api/MarketResearchAPI.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  Map<String, dynamic> _customData = {
    'category': '',
    'businessScale': '',
    'nation': '',
    'customerType': '',
    'businessType': '',
    'businessContent': '',
    'businessPlatform': '',
    'investmentStatus': ''
  };

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
    _fetchCategories();
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
        _error = '사업 정보를 불러오는데 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      _categories = await MarketResearchApi.fetchCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      _error = '카테고리 목록을 불러오는데 실패했습니다: $e';
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
            DropdownButtonFormField<Map<String, dynamic>?>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '사업 선택',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              value: _selectedBusiness,
              items: [
                DropdownMenuItem<Map<String, dynamic>?>(
                  value: null,
                  child: Text('선택안함'),
                ),
                ..._businesses.map((business) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: business,
                    child: Text(business['businessName'] ?? ''),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBusiness = value;
                  if (value != null) {
                    _customData = Map.from(value);
                  } else {
                    _customData = {
                      'category': '',
                      'businessScale': '',
                      'nation': '',
                      'customerType': '',
                      'businessType': '',
                      'businessContent': '',
                      'businessPlatform': '',
                      'investmentStatus': ''
                    };
                  }
                });
              },
            ),
            SizedBox(height: 16),
            if (_selectedBusiness == null) _buildCustomDataForm(),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text('다음'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCustomDataForm() {
    return Column(
      children: [
        _buildDropdownField('사업 분야 (카테고리)', 'category', _categories),
        _buildInputField('사업 규모', 'businessScale', '예: 중소기업'),
        _buildInputField('국가', 'nation', '예: 대한민국'),
        _buildInputField('고객유형', 'customerType', '예: B2B'),
        _buildInputField('사업유형', 'businessType', '예: 소프트웨어 개발'),
        _buildInputField('사업내용', 'businessContent', '사업 내용을 간략히 설명해주세요'),
        _buildInputField('사업 플랫폼', 'businessPlatform', '예: 모바일 앱'),
        _buildInputField('투자 상태', 'investmentStatus', '예: 시드 투자 유치'),
      ],
    );
  }

  Widget _buildDropdownField(String label, String field, List<String> items) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: _customData[field],
        items: [
          DropdownMenuItem<String>(child: Text('선택하세요'), value: ''),
          ...items.map((item) => DropdownMenuItem<String>(child: Text(item), value: item)).toList(),
        ],
        onChanged: (value) {
          setState(() {
            _customData[field] = value;
          });
        },
      ),
    );
  }

  Widget _buildInputField(String label, String field, String placeholder) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          border: OutlineInputBorder(),
        ),
        initialValue: _customData[field],
        onChanged: (value) {
          setState(() {
            _customData[field] = value;
          });
        },
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
    if (_selectedBusiness == null && _customData['category'].isEmpty) {
      setState(() {
        _error = '사업을 선택하거나 카테고리를 입력해주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

try {
final data = _selectedBusiness ?? _customData;
Map<String, dynamic> analysisResult = {};

if (type == 'all' || type == 'marketSize') {
try {
analysisResult = await MarketResearchApi.analyzeMarketSize(data);
_marketSizeGrowth = analysisResult;
} catch (error) {
print('Market size analysis failed: $error');
Fluttertoast.showToast(
msg: "시장 규모 분석 중 오류가 발생했습니다.",
toastLength: Toast.LENGTH_LONG,
gravity: ToastGravity.BOTTOM,
);
}
}

if (type == 'all' || type == 'similarServices') {
try {
analysisResult = await MarketResearchApi.analyzeSimilarServices(data);
_similarServices = analysisResult;
} catch (error) {
print('Similar services analysis failed: $error');
Fluttertoast.showToast(
msg: "관련 유사서비스가 없습니다.",
toastLength: Toast.LENGTH_LONG,
gravity: ToastGravity.BOTTOM,
);
}
}

if (type == 'all' || type == 'trendCustomerTechnology') {
try {
analysisResult = await MarketResearchApi.analyzeTrendCustomerTechnology(data);
_trendCustomerTechnology = analysisResult;
} catch (error) {
print('Trend analysis failed: $error');
Fluttertoast.showToast(
msg: "트렌드, 고객, 기술 분석 중 오류가 발생했습니다.",
toastLength: Toast.LENGTH_LONG,
gravity: ToastGravity.BOTTOM,
);
}
}

// businessId 처리 개선
int businessId = _selectedBusiness != null ? _selectedBusiness!['id'] : 0;

try {
String saveResult = await MarketResearchApi.saveHistory({
'createAt': DateTime.now().toIso8601String(),
'marketInformation': jsonEncode(_marketSizeGrowth ?? {'businessId': businessId, 'marketSize': '정보 없음', 'growthRate': '정보 없음'}),
'competitorAnalysis': jsonEncode(_similarServices ?? {}),
'marketTrends': jsonEncode(_trendCustomerTechnology ?? {}),
'businessId': businessId,
});

print('Save history result: $saveResult');
} catch (saveError) {
print('History save failed: $saveError');
Fluttertoast.showToast(
msg: "등록되지 않은 사업의 분석은 잠시동안만 저장됩니다.",
toastLength: Toast.LENGTH_LONG,
gravity: ToastGravity.BOTTOM,
);
}

setState(() {
_currentStep = 2;
});
} catch (e) {
setState(() {
_error = '시장 분석 중 일부 오류가 발생했습니다. 일부 결과만 표시될 수 있습니다.';
});
} finally {
setState(() {
_isLoading = false;
});
}
}


  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_marketSizeGrowth != null) ...[
          Text('시장 규모 및 성장률', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          _buildMarketSizeGrowthChart(_marketSizeGrowth!),
        ],
        if (_similarServices != null) ...[
          SizedBox(height: 16),
          Text('유사 서비스 분석', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          _buildSimilarServicesAnalysis(_similarServices!),
        ],
        if (_trendCustomerTechnology != null) ...[
          SizedBox(height: 16),
          Text('트렌드, 고객 분포, 기술 동향', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          _buildTrendCustomerTechnologyAnalysis(_trendCustomerTechnology!),
        ],
        SizedBox(height: 16),
        ElevatedButton(
          child: Text('새로운 분석 시작'),
          onPressed: _handleNewAnalysis,
        ),
      ],
    );
  }

  Widget _buildMarketSizeGrowthChart(Map<String, dynamic> data) {
    // Implement chart using fl_chart package
    return Container(
      height: 300,
      child: LineChart(
        LineChartData(
          // Configure chart data here
        ),
      ),
    );
  }

  Widget _buildSimilarServicesAnalysis(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['analysis'] ?? '분석 데이터가 없습니다.'),
      ],
    );
  }

  Widget _buildTrendCustomerTechnologyAnalysis(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('트렌드: ${data['trend'] ?? '데이터 없음'}'),
        SizedBox(height: 8),
        Text('주요 고객: ${data['mainCustomers'] ?? '데이터 없음'}'),
        SizedBox(height: 8),
        Text('기술 동향: ${data['technologyTrend'] ?? '데이터 없음'}'),
      ],
    );
  }

  Widget _buildResearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('조회 이력', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        if (_researchHistory.isEmpty)
          Text('조회 이력이 없습니다.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _researchHistory.length,
            itemBuilder: (context, index) {
              final history = _researchHistory[index];
              return ListTile(
                title: Text(history['createAt'] ?? '날짜 없음'),
                subtitle: Text(history['businessName'] ?? '사업명 없음'),
                onTap: () => _showHistoryDetail(history),
              );
            },
          ),
      ],
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

  void _handleNewAnalysis() {
    setState(() {
      _selectedBusiness = null;
      _customData = {
        'category': '',
        'businessScale': '',
        'nation': '',
        'customerType': '',
        'businessType': '',
        'businessContent': '',
        'businessPlatform': '',
        'investmentStatus': ''
      };
      _marketSizeGrowth = null;
      _similarServices = null;
      _trendCustomerTechnology = null;
      _error = null;
      _currentStep = 0;
    });
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
    : Column(
children: [
Padding(
padding: EdgeInsets.all(16.0),
child: _buildStepIndicator(),
),
TabBar(
controller: _tabController,
tabs: [
Tab(text: '시장 분석'),
Tab(text: '조회 이력'),
],
),
Expanded(
child: TabBarView(
controller: _tabController,
children: [
// Market Analysis Tab
SingleChildScrollView(
child: Padding(
padding: EdgeInsets.all(16.0),
child: Column(
children: [
if (_currentStep == 0) _buildBusinessSelection(),
if (_currentStep == 1) _buildAnalysisTypeSelection(),
if (_currentStep == 2) _buildResults(),
],
),
),
),
// History Tab
SingleChildScrollView(
child: Padding(
padding: EdgeInsets.all(16.0),
child: _buildResearchHistory(),
),
),
],
),
),
],
),
);
}
}