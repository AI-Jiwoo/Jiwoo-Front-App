import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'business_info_form.dart';

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
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchBusinessInfos();
    fetchCategories();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access-token');
    await prefs.remove('refresh-token');
    Navigator.of(context).pushReplacementNamed('/'); // 로그인 페이지로 이동
  }

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://13.124.128.228:5000/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept-Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userInfo = json.decode(utf8.decode(response.bodyBytes));
          // birthDate를 String으로 저장
          if (userInfo['birthDate'] != null) {
            if (userInfo['birthDate'] is String) {
              // 이미 String이면 그대로 사용
              userInfo['birthDate'] = userInfo['birthDate'];
            } else {
              // DateTime 객체라면 ISO 8601 형식의 String으로 변환
              userInfo['birthDate'] = DateTime.parse(userInfo['birthDate']).toIso8601String();
            }
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
        Uri.parse('http://13.124.128.228:5000/business/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept-Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          businessInfos = List<Map<String, dynamic>>.from(data['business']);
        });
      } else {
        throw Exception('Failed to load business infos');
      }
    } catch (e) {
      print('Error fetching business infos: $e');
    }
  }

  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://13.124.128.228:5000/category/names'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept-Charset': 'utf-8',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded data: $data');

        setState(() {
          categories = data.asMap().entries.map((entry) {
            return {
              'id': entry.key.toString(),
              'name': entry.value as String,
            };
          }).toList();
        });
        print('Processed categories: $categories');
      } else {
        throw HttpException('Failed to load categories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> handleSaveInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://13.124.128.228:5000/auth/edit/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'gender': userInfo['gender'],
          'phoneNo': userInfo['phoneNo'],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('개인정보가 성공적으로 저장되었습니다.')),
        );
      } else {
        throw Exception('Failed to save user info');
      }
    } catch (e) {
      print('Error saving user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('개인정보 저장에 실패했습니다.')),
      );
    }
  }

  Future<void> handlePasswordChange() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (_oldPasswordController.text == _newPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('새 비밀번호가 현재 비밀번호와 같습니다. 다른 비밀번호를 선택해주세요.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://13.124.128.228:5000/auth/edit/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        Navigator.of(context).pop(); // 모달 닫기
      } else {
        throw Exception('Failed to change password');
      }
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 변경에 실패했습니다.')),
      );
    }
  }

  void showPasswordChangeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('비밀번호 변경'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '현재 비밀번호'),
                ),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '새 비밀번호'),
                ),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '새 비밀번호 확인'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('변경'),
              onPressed: handlePasswordChange,
            ),
          ],
        );
      },
    );
  }

  void showAddBusinessForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('사업 정보 추가'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: BusinessInfoForm(
                onSubmit: handleSubmitBusinessInfo,
                categories: categories,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> handleSubmitBusinessInfo(Map<String, dynamic> newBusinessInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token') ?? '';

    try {
      print('Submitting business info: $newBusinessInfo'); // 디버깅용 로그

      final response = await http.post(
        Uri.parse('http://13.124.128.228:5000/business/regist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(newBusinessInfo),
      );

      print('Response status code: ${response.statusCode}'); // 디버깅용 로그
      print('Response body: ${response.body}'); // 디버깅용 로그

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사업 정보가 성공적으로 저장되었습니다.')),
        );
        fetchBusinessInfos(); // 사업 정보 목록 새로고침
        Navigator.of(context).pop(); // 모달 닫기
      } else {
        // 서버에서 반환된 오류 메시지 확인
        var errorMessage = '사업 정보 저장에 실패했습니다.';
        try {
          var errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          print('Error parsing error message: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error saving business info: $e'); // 디버깅용 로그
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사업 정보 저장에 실패했습니다. 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
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
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _logout,
                  child: Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기본정보',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                )
            ),
            SizedBox(height: 16),
            _buildInfoItem('이메일', userInfo['email'] ?? ''),
            _buildInfoItem('이름', userInfo['name'] ?? ''),
            _buildEditableInfoItem('전화번호', userInfo['phoneNo'] ?? '', (value) {
              setState(() => userInfo['phoneNo'] = value);
            }),
            _buildDatePickerItem('생년월일', userInfo['birthDate']),
            _buildGenderDropdown(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: showPasswordChangeModal,
                  child: Text('비밀번호 변경'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(width: 8),
                FilledButton(
                  onPressed: handleSaveInfo,
                  child: Text('저장'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoItem(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDatePickerItem(String label, dynamic date) {
    // date가 String인 경우 DateTime으로 변환
    DateTime? dateTime;
    if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        print('Error parsing date: $e');
      }
    } else if (date is DateTime) {
      dateTime = date;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: dateTime ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => userInfo['birthDate'] = picked.toIso8601String());
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                child: Text(
                  dateTime != null ? DateFormat('yyyy-MM-dd').format(dateTime) : '선택해주세요',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGenderDropdown() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('성별', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: userInfo['gender'] ?? '',
              items: [
                DropdownMenuItem(child: Text('선택하세요'), value: ''),
                DropdownMenuItem(child: Text('남성'), value: 'MALE'),
                DropdownMenuItem(child: Text('여성'), value: 'FEMALE'),
              ],
              onChanged: (value) {
                setState(() {
                  userInfo['gender'] = value;
                  print('Selected gender: $value'); // 디버깅용 로그
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사업정보',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface
            )
        ),
        SizedBox(height: 16),
        ...businessInfos.map((info) => _buildBusinessCard(info)).toList(),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: showAddBusinessForm,
          icon: Icon(Icons.add),
          label: Text('사업 추가'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> info) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    info['businessName'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(_getBusinessScaleText(info['businessScale'])),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildBusinessInfoItem('사업자 번호', info['businessNumber'] ?? ''),
            _buildBusinessInfoItem('사업 내용', info['businessContent'] ?? ''),
            _buildBusinessInfoItem('위치', info['businessLocation'] ?? ''),
            _buildBusinessInfoItem('시작일', info['businessStartDate'] ?? ''),
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
            child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
            )),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
            )),
          ),
        ],
      ),
    );
  }


  String _getBusinessScaleText(String? scale) {
    switch (scale) {
      case 'small':
        return '스타트업';
      case 'medium':
        return '중소기업';
      case 'large':
        return '중견기업';
      default:
        return '미정';
    }
  }
}