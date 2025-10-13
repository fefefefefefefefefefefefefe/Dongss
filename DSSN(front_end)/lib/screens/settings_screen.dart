import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 연한 회색 배경
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아가기
          },
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Color(0xFF1E8854), // 메인 초록색
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // 알림 설정
          _buildSettingsTile(
            context,
            Icons.notifications_outlined,
            '알림 설정',
                () {
              // TODO: 알림 설정 페이지로 이동
            },
          ),
          // 계정 관리
          _buildSettingsTile(
            context,
            Icons.manage_accounts_outlined,
            '계정 관리',
                () {
              // TODO: 계정 관리 페이지로 이동
            },
          ),
          // 로그아웃
          _buildSettingsTile(
            context,
            Icons.logout,
            '로그아웃',
                () {
              // TODO: 로그아웃 기능 구현
            },
          ),
        ],
      ),
    );
  }

  // 설정 항목 위젯
  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black54),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16), // 구분선
      ],
    );
  }
}