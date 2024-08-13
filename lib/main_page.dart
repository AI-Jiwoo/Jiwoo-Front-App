import 'dart:convert';

import 'package:flutter/material.dart';
import 'Business_Model.dart';
import 'login_page.dart';
import 'join_page.dart';
import 'marketResearch_page.dart';
import 'my_page.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jiwoo AI Helper',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
      routes: {
        '/main': (context) => MainPage(),
        '/join': (context) => JoinPage(),
        '/mypage': (context) => MyPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeTab(),
    MarketResearchPage(),
    BusinessModelTab(),
    MyPage(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jiwoo AI Helper'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _pages[_selectedIndex], // 선택된 인덱스에 해당하는 페이지를 표시
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}
class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero section
          Container(
            height: 300,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: Text(
                'Jiwoo AI Helper',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          // Features section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 기능',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                FeatureCard(
                  title: '창업 가이드',
                  description: 'AI 기반 맞춤형 창업 전략',
                  icon: Icons.lightbulb, onTap: () {},
                ),
                FeatureCard(
                  title: '비즈니스 모델',
                  description: '혁신적인 비즈니스 모델 설계',
                  icon: Icons.business,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BusinessModelPage()),
                    );
                  },                ),
                FeatureCard(
                  title: '시장 조사',
                  description: 'AI 기반 시장 트렌드 분석',
                  icon: Icons.trending_up,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MarketResearchPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class MarketResearchTab extends StatefulWidget {
  @override
  _MarketResearchTabState createState() => _MarketResearchTabState();
}

class _MarketResearchTabState extends State<MarketResearchTab> {
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
      final response = await http.get(
        Uri.parse('http://localhost:5000/business/user'),
        headers: {'Authorization': 'Bearer ${await _getToken()}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _businesses = List<Map<String, dynamic>>.from(data['business'] ?? []);
        });
      } else {
        throw Exception('Failed to load businesses');
      }
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
            Text('사업 선택', style: Theme.of(context).textTheme.titleLarge),
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
            Text('분석 유형 선택', style: Theme.of(context).textTheme.titleLarge),
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
    return _isLoading
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
    );
  }
}

class BusinessModelTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BusinessModelPage();
  }
}
class MyPageTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('My Page'));
  }
}