import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BusinessInfoForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final List<Map<String, dynamic>> categories;

  BusinessInfoForm({required this.onSubmit, required this.categories});

  @override
  _BusinessInfoFormState createState() => _BusinessInfoFormState();
}

class _BusinessInfoFormState extends State<BusinessInfoForm> {
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
    'categoryIds': <String>[]  // String 리스트로 변경
  };

  final TextEditingController _dateController = TextEditingController();

  bool isValidBusinessNumber(String value) {
    RegExp regExp = RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return regExp.hasMatch(value);
  }

  @override
  void initState() {
    super.initState();
    print('Available categories: ${widget.categories}');
  }

  List<String> countries = [
    "대한민국", "미국", "일본", "중국", "영국", "프랑스", "독일", "캐나다", "호주", "뉴질랜드",
    "이탈리아", "스페인", "러시아", "브라질", "인도", "싱가포르", "말레이시아", "태국", "베트남", "인도네시아"
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: '사업이름'),
              validator: (value) => value!.isEmpty ? '사업이름을 입력해주세요' : null,
              onSaved: (value) => businessInfo['businessName'] = value,
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: '사업자 등록번호',
                hintText: '000-00-00000',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              validator: (value) {
                if (value!.isEmpty) {
                  return '사업자 등록번호를 입력해주세요';
                }
                if (!isValidBusinessNumber(value)) {
                  return '올바른 사업자 등록번호 형식이 아닙니다 (000-00-00000)';
                }
                return null;
              },
              onSaved: (value) => businessInfo['businessNumber'] = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '사업 자본'),
              onSaved: (value) => businessInfo['businessBudget'] = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '사업내용'),
              maxLines: 3,
              validator: (value) => value!.isEmpty ? '사업내용을 입력해주세요' : null,
              onSaved: (value) => businessInfo['businessContent'] = value,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '사업규모'),
              value: businessInfo['businessScale'],
              items: ['', 'small', 'medium', 'large'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.isEmpty ? '선택해주세요' :
                  value == 'small' ? '스타트업' :
                  value == 'medium' ? '중소기업' : '중견기업'),
                );
              }).toList(),
              onChanged: (value) => setState(() => businessInfo['businessScale'] = value),
              validator: (value) => value == null || value.isEmpty ? '사업규모를 선택해주세요' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '사업형태'),
              onSaved: (value) => businessInfo['businessPlatform'] = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '사업위치'),
              validator: (value) => value!.isEmpty ? '사업위치를 입력해주세요' : null,
              onSaved: (value) => businessInfo['businessLocation'] = value,
            ),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: '창업일자',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                  setState(() {
                    _dateController.text = formattedDate;
                    businessInfo['businessStartDate'] = formattedDate;
                  });
                }
              },
              validator: (value) => value!.isEmpty ? '창업일자를 선택해주세요' : null,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '국가'),
              value: businessInfo['nation'],
              items: ['', ...countries].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.isEmpty ? '선택해주세요' : value),
                );
              }).toList(),
              validator: (value) => value == null || value.isEmpty ? '국가를 선택해주세요' : null,
              onChanged: (value) => setState(() => businessInfo['nation'] = value),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '투자상태'),
              onSaved: (value) => businessInfo['investmentStatus'] = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '고객유형'),
              onSaved: (value) => businessInfo['customerType'] = value,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '창업 단계'),
              value: businessInfo['startupStageId'],
              items: ['', '1', '2', '3', '4', '5'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.isEmpty ? '선택해주세요' : '$value단계'),
                );
              }).toList(),
              validator: (value) => value == null || value.isEmpty ? '창업 단계를 선택해주세요' : null,
              onChanged: (value) => setState(() => businessInfo['startupStageId'] = value),
            ),
            // 카테고리 다중 선택을 위한 CheckboxListTile 리스트
            ...widget.categories.map((category) => CheckboxListTile(
              title: Text(category['name']),
              value: (businessInfo['categoryIds'] as List<String>).contains(category['id'].toString()),  // String으로 변환
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    (businessInfo['categoryIds'] as List<String>).add(category['id'].toString());
                  } else {
                    (businessInfo['categoryIds'] as List<String>).remove(category['id'].toString());
                  }
                });
              },
            )).toList(),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('저장'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if ((businessInfo['categoryIds'] as List<String>).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('최소 하나의 카테고리를 선택해주세요.')),
                    );
                  } else {
                    widget.onSubmit(businessInfo);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('모든 필수 항목을 입력해주세요.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
