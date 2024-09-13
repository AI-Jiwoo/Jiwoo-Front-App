import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _password = '';
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  _loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail') ?? '';
    setState(() {
      _emailController.text = savedEmail;
      _rememberMe = savedEmail.isNotEmpty;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('savedEmail', _emailController.text);
      } else {
        await prefs.remove('savedEmail');
      }

      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/login'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': _emailController.text,
            'password': _password,
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final token = response.headers['authorization'];
          if (token != null && token.startsWith('Bearer ')) {
            final jwt = token.substring(7);
            final decodedToken = Jwt.parseJwt(jwt);

            await prefs.setString('access-token', jwt);
            await prefs.setString('refresh-token', jwt);

            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            throw Exception('Invalid token received');
          }
        } else {
          throw Exception('Login failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Login error: $e');
        String errorMessage = '로그인 실패: ';
        if (e is TimeoutException) {
          errorMessage += '서버 응답 시간 초과';
        } else if (e is SocketException) {
          errorMessage += '네트워크 연결 오류';
        } else {
          errorMessage += e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'LOGIN',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'EMAIL',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? '이메일을 입력해주세요' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'PASSWORD',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? '비밀번호를 입력해주세요' : null,
                    onChanged: (value) => setState(() => _password = value),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      Text('아이디 저장'),
                      Spacer(),
                      TextButton(
                        child: Text('아이디 찾기'),
                        onPressed: () {/* TODO: Implement */},
                      ),
                      Text('|'),
                      TextButton(
                        child: Text('비밀번호 찾기'),
                        onPressed: () {/* TODO: Implement */},
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('로그인', style: TextStyle(fontSize: 18)),
                    ),
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('회원가입', style: TextStyle(fontSize: 18)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/join'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}