// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _studentIdController = TextEditingController();

  String? _selectedGender;
  String? _selectedMajor;
  DateTime? _selectedDateOfBirth;

  bool _isLoading = false;

  // 💡 동서울대학교 학과 목록을 반영했습니다.
  final List<String> _majorOptions = [
    '미래항공과',
    '미래자동차학과',
    '전기공학과',
    '전자공학과',
    'IT융합학과',
    '컴퓨터소프트웨어학과',
    '건축학과',
    '컴퓨터정보과',
    '디지털방송콘텐츠학과',
    '실내디자인학과',
    '게임콘텐츠과',
    '스마트드론과',
    '디지털헬스케어과',
    '호텔외식조리과',
    '보건의료행정과',
    '세무회계과',
    '마케팅과',
    '도시계획부동산학과',
    '호텔관광경영과',
    '아동보육과',
    '사회복지학과',
    '항공서비스학과',
    '글로벌중국비즈니스과',
    '사회복지상담과',
    '레저스포츠학과',
    '경호스포츠과',
    '산업디자인학과',
    '시각디자인학과',
    '패션디자인과',
    '주얼리디자인과',
    '뷰티디자인과',
    '연기예술학과',
    '실용음악학과',
    'K-POP과',
    '콘텐츠크리에이터과',
    '엔터테인먼트경영과',
    '메타버스게임애니메이션과',
    '무대미술과',
    '웹툰과',
    '자유전공학과',
    '기타/전공선택',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _submitSignup() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nicknameController.text.isEmpty ||
        _studentIdController.text.isEmpty ||
        _selectedGender == null ||
        _selectedMajor == null ||
        _selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력하거나 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signup(
        _emailController.text,
        _passwordController.text,
        _nicknameController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인 해주세요.')),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 이메일 입력
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '학교 이메일',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // 2. 비밀번호 입력
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호 (8자 이상)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 3. 닉네임 입력
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_pin),
              ),
            ),
            const SizedBox(height: 16),

            // 4. 학번 입력
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '학번 (예: 20231234)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 5. 성별 (드롭다운)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '성별',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              value: _selectedGender,
              hint: const Text('성별 선택'),
              items: <String>['남성', '여성']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // 6. 학과 (드롭다운)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '학과',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment),
              ),
              value: _selectedMajor,
              hint: const Text('학과 선택'),
              items: _majorOptions
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMajor = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // 7. 생년월일 (피커)
            GestureDetector(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '생년월일',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDateOfBirth == null
                      ? '생년월일 선택'
                      : '${_selectedDateOfBirth!.year}년 ${_selectedDateOfBirth!.month}월 ${_selectedDateOfBirth!.day}일',
                  style: TextStyle(fontSize: 16, color: _selectedDateOfBirth == null ? Colors.grey : Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 회원가입 버튼 (스크롤을 내려야 보임)
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submitSignup,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF1E8854),
              ),
              child: const Text('회원가입 완료', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}