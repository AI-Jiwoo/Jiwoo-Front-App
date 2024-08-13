import 'package:flutter/material.dart';
import 'login_page.dart';
import 'join_page.dart';
import 'my_page.dart';
import 'main_page.dart'; // 새로 만든 MainPage를 import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Building MyApp');
    return MaterialApp(
      title: 'Jiwoo AI Helper',
      theme: ThemeData(
        useMaterial3: true, // Material 3 사용
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          print('Navigating to LoginPage');
          return LoginPage();
        },
        '/home': (context) {
          print('Navigating to HomePage');
          return HomePage();
        },
        '/join': (context) {
          print('Navigating to JoinPage');
          return JoinPage();
        },
        '/mypage': (context) {
          print('Navigating to MyPage');
          return MyPage();
        },
        '/home': (context) {
          print('Navigating to MainPage');
          return MainPage();
        },
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Building HomePage');
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Home Page'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Go to My Page'),
              onPressed: () => Navigator.pushNamed(context, '/mypage'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Go to Main Page'),
              onPressed: () => Navigator.pushNamed(context, '/main'),
            ),
          ],
        ),
      ),
    );
  }
}