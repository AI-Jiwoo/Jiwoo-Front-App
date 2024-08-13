import 'package:flutter/material.dart';
import 'login_page.dart';
import 'join_page.dart';
import 'my_page.dart';
import 'main_page.dart';

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

  static List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    MarketResearchTab(),
    BusinessModelTab(),
    MyPageTab(),
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
      body: _widgetOptions.elementAt(_selectedIndex),
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
                  icon: Icons.lightbulb,
                ),
                FeatureCard(
                  title: '비즈니스 모델',
                  description: '혁신적인 비즈니스 모델 설계',
                  icon: Icons.business,
                ),
                FeatureCard(
                  title: '시장 조사',
                  description: 'AI 기반 시장 트렌드 분석',
                  icon: Icons.trending_up,
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

  const FeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
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
      ),
    );
  }
}

// Placeholder widgets for other tabs
class MarketResearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Market Research'));
  }
}

class BusinessModelTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Business Model'));
  }
}

class MyPageTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('My Page'));
  }
}