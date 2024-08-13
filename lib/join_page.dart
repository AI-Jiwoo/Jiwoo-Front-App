import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class JoinPage extends StatefulWidget {
  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  String _name = '';
  String _email = '';
  String _password = '';
  DateTime? _birthDate;
  bool _isEmailVerified = false;
  bool _isLoading = false;

  Future<void> _checkEmail() async {
    if (_email.isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/exist/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email}),
      );

      if (response.statusCode == 200) {
        setState(() => _isEmailVerified = true);
        _showSnackBar('사용 가능한 이메일입니다.');
      } else {
        _showSnackBar('중복된 이메일입니다. 다른 이메일을 사용해주세요.');
      }
    } catch (e) {
      _showSnackBar('이메일 확인 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEmailVerified) {
      _showSnackBar('이메일 중복 확인을 해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formattedDate = _birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
          : '';

      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _name,
          'email': _email,
          'password': _password,
          'birthDate': formattedDate,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('회원가입이 완료되었습니다.');
        setState(() => _currentStep = 2);
      } else {
        throw Exception('회원가입 실패: ${response.body}');
      }
    } catch (e) {
      print('Signup error: $e');
      _showSnackBar('회원가입 중 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTermsStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이용약관', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            _buildCheckboxTile(
              title: '홈페이지 이용약관 동의 (필수)',
              value: _termsAgreed,
              onChanged: (value) => setState(() => _termsAgreed = value!),
            ),
            _buildTermsContainer('이용약관 내용...'),
            SizedBox(height: 16),
            _buildCheckboxTile(
              title: '개인정보 이용약관 동의 (필수)',
              value: _privacyAgreed,
              onChanged: (value) => setState(() => _privacyAgreed = value!),
            ),
            _buildTermsContainer('개인정보 약관 내용...'),
            SizedBox(height: 24),
            _buildButton(
              text: '다음단계',
              onPressed: (_termsAgreed && _privacyAgreed)
                  ? () => setState(() => _currentStep = 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('회원정보', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              _buildTextField(
                label: '이름',
                onChanged: (value) => setState(() => _name = value),
                validator: (value) => value!.isEmpty ? '이름을 입력해주세요' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: '이메일',
                      onChanged: (value) => setState(() {
                        _email = value;
                        _isEmailVerified = false;
                      }),
                      validator: (value) => value!.isEmpty ? '이메일을 입력해주세요' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    child: Text('중복 확인'),
                    onPressed: _checkEmail,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: '비밀번호',
                obscureText: true,
                onChanged: (value) => setState(() => _password = value),
                validator: (value) => value!.isEmpty ? '비밀번호를 입력해주세요' : null,
              ),
              SizedBox(height: 16),
              _buildDateField(),
              SizedBox(height: 24),
              _buildButton(text: '가입완료', onPressed: _signUp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('가입이 완료되었습니다!', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Text('가입해 주셔서 감사합니다. 더 나은 서비스로 보답하겠습니다.'),
            SizedBox(height: 24),
            _buildButton(
              text: '로그인하기',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({required String title, required bool value, required Function(bool?) onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blue,
    );
  }

  Widget _buildTermsContainer(String content) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Text(content),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: '생년월일',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _birthDate = date);
        }
      },
      readOnly: true,
      controller: TextEditingController(
        text: _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : "",
      ),
      validator: (value) => value!.isEmpty ? '생년월일을 선택해주세요' : null,
    );
  }

  Widget _buildButton({required String text, required VoidCallback? onPressed}) {
    return ElevatedButton(
      child: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) => Container(),
          steps: [
            Step(
              title: Text('약관동의'),
              content: _buildTermsStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('회원정보'),
              content: _buildInfoStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text('가입완료'),
              content: _buildCompletionStep(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}