import 'package:flutter/material.dart';
import 'login_page.dart';
import 'join_page.dart';
import 'my_page.dart';  // MyPage를 import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Building MyApp'); // 디버그 출력
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          print('Navigating to LoginPage'); // 디버그 출력
          return LoginPage();
        },
        '/home': (context) {
          print('Navigating to HomePage'); // 디버그 출력
          return HomePage();
        },
        '/join': (context) {
          print('Navigating to JoinPage'); // 디버그 출력
          return JoinPage();
        },
        '/mypage': (context) {
          print('Navigating to MyPage'); // 디버그 출력
          return MyPage();
        },
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Building HomePage'); // 디버그 출력
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Home Page'),
            ElevatedButton(
              child: Text('Go to My Page'),
              onPressed: () => Navigator.pushNamed(context, '/mypage'),
            ),
          ],
        ),
      ),
    );
  }
}