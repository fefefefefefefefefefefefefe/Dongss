// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text,
        _passwordController.text,
      );
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
        title: const Text('로그인'),
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Dong Story',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E8854),
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 (e.g., student@school.ac.kr)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF1E8854),
                ),
                child: const Text('로그인', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text('계정이 없으신가요? 회원가입', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
