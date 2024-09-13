import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomBusinessInfoForm extends StatefulWidget {
  final List<String> categories;
  final Function(Map<String, dynamic>) onSubmit;

  const CustomBusinessInfoForm({
    Key? key,
    required this.categories,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CustomBusinessInfoFormState createState() => _CustomBusinessInfoFormState();
}

class _CustomBusinessInfoFormState extends State<CustomBusinessInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> businessInfo = {
    'businessName': '',
    'businessNumber': '',
    'businessScale': '',
    'businessBudget': '',
    'businessContent': '',
    'businessPlatform': '',
    'businessLocation': '',
    'businessStartDate': '',
    'nation': '',
    'investmentStatus': '',
    'customerType': '',
    'startupStageId': '',
    'categoryIds': <String>[]
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('사업명', 'businessName'),
            _buildTextField('사업자 번호', 'businessNumber'),
            _buildDropdownField('사업 규모', 'businessScale', ['소상공인', '중소기업', '중견기업', '대기업']),
            _buildTextField('예산', 'businessBudget'),
            _buildTextField('사업 내용', 'businessContent', maxLines: 3),
            _buildTextField('사업 플랫폼', 'businessPlatform'),
            _buildTextField('사업 위치', 'businessLocation'),
            _buildDateField('사업 시작일', 'businessStartDate'),
            _buildTextField('국가', 'nation'),
            _buildDropdownField('투자 상태', 'investmentStatus', ['미투자', '투자유치', '투자 진행중']),
            _buildDropdownField('고객 유형', 'customerType', ['B2C', 'B2B', 'B2G']),
            _buildDropdownField('스타트업 단계', 'startupStageId', ['아이디어', '프로토타입', '초기', '성장', '성숙']),
            _buildCategoryMultiSelect(),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('제출'),
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String field, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        maxLines: maxLines,
        onSaved: (value) => businessInfo[field] = value,
        validator: (value) => value!.isEmpty ? '이 필드는 필수입니다' : null,
      ),
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
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            businessInfo[field] = value;
          });
        },
        validator: (value) => value == null ? '이 필드는 필수입니다' : null,
      ),
    );
  }

  Widget _buildDateField(String label, String field) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        controller: TextEditingController(text: businessInfo[field]), // Initialize with current value
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
            setState(() {
              businessInfo[field] = formattedDate;
            });
          }
        },
        validator: (value) => value!.isEmpty ? '이 필드는 필수입니다' : null,
      ),
    );
  }

  Widget _buildCategoryMultiSelect() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '카테고리',
          border: OutlineInputBorder(),
        ),
        items: widget.categories.isEmpty
            ? [DropdownMenuItem<String>(value: '', child: Text('카테고리 없음'))]
            : widget.categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null && newValue.isNotEmpty) {
            setState(() {
              if (!businessInfo['categoryIds'].contains(newValue)) {
                businessInfo['categoryIds'].add(newValue);
              }
            });
          }
        },
        validator: (value) => businessInfo['categoryIds'].isEmpty ? '최소 한 개의 카테고리를 선택해주세요' : null,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(businessInfo);
    }
  }
}
