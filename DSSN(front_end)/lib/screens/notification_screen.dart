import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          '알림',
          style: TextStyle(
            color: Color(0xFF1E8854),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildNotificationTile(
            context,
            '새로운 좋아요',
            '익명의 동서인님이 내 게시물을 좋아합니다.',
            '10분 전',
          ),
          _buildNotificationTile(
            context,
            '새로운 댓글',
            '이민재님이 내 게시물에 댓글을 달았습니다.',
            '1시간 전',
          ),
          _buildNotificationTile(
            context,
            '새로운 팔로워',
            '김아영님이 나를 팔로우하기 시작했습니다.',
            '3시간 전',
          ),
          _buildNotificationTile(
            context,
            '댓글',
            '홍길동님이 내 게시물에 댓글을 달았습니다.',
            '1일 전',
          ),
        ],
      ),
    );
  }

  // 알림 항목 위젯
  Widget _buildNotificationTile(BuildContext context, String title, String content, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF66BB6A),
            radius: 20,
            child: Icon(Icons.person, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}