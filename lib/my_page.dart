import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Map<String, dynamic> userInfo = {
    'name': '',
    'email': '',
    'phoneNo': '',
    'birthDate': null,
    'gender': ''
  };
  List<Map<String, dynamic>> businessInfos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchBusinessInfos();
  }

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userInfo = json.decode(response.body);
          if (userInfo['birthDate'] != null) {
            userInfo['birthDate'] = DateTime.parse(userInfo['birthDate']);
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user info');
      }
    } catch (e) {
      print('Error fetching user info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchBusinessInfos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/business/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          businessInfos = List<Map<String, dynamic>>.from(json.decode(response.body)['business']);
        });
      } else {
        throw Exception('Failed to load business infos');
      }
    } catch (e) {
      print('Error fetching business infos: $e');
    }
  }


  // fetchUserInfo 및 fetchBusinessInfos 메소드는 그대로 유지

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: Color(0xFF007BFF), // Bootstrap primary color
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoSection(),
              SizedBox(height: 24),
              _buildBusinessInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기본정보', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildInfoItem('이메일', userInfo['email']),
            _buildInfoItem('이름', userInfo['name']),
            _buildInfoItem('전화번호', userInfo['phoneNo']),
            _buildInfoItem('생년월일', userInfo['birthDate'] != null
                ? DateFormat('yyyy-MM-dd').format(userInfo['birthDate'])
                : '미설정'),
            _buildInfoItem('성별', userInfo['gender'] == 'MALE' ? '남성' : '여성'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement password change functionality
                  },
                  child: Text('비밀번호 변경'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF007BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement save functionality
                  },
                  child: Text('저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745), // Bootstrap success color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사업정보', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        businessInfos.isEmpty
            ? Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('등록된 사업정보가 없습니다.'),
          ),
        )
            : Column(
          children: businessInfos.map((info) => _buildBusinessCard(info)).toList(),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement add business functionality
          },
          icon: Icon(Icons.add),
          label: Text('사업 추가'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF007BFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> info) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(info['businessName'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF17A2B8), // Bootstrap info color
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    info['businessScale'],
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildBusinessInfoItem('사업자 번호', info['businessNumber']),
            _buildBusinessInfoItem('사업 내용', info['businessContent']),
            _buildBusinessInfoItem('위치', info['businessLocation']),
            _buildBusinessInfoItem('시작일', info['businessStartDate']),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}