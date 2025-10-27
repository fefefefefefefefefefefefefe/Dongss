// lib/screens/friends_management_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/user.dart'; // User 모델 임포트 가정

class FriendsManagementScreen extends StatelessWidget {
  const FriendsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.loggedInUser;

    // 현재 로그인된 사용자의 친구 ID 목록
    final List<String> friendIds = currentUser?.friends ?? [];

    // 친구 ID를 바탕으로 User 객체 정보를 가져옵니다.
    final List<User> friends = friendIds
        .map((id) => authProvider.getUserById(id))
        .where((user) => user != null)
        .cast<User>() // null이 아닌 User 객체만 필터링
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        backgroundColor: const Color(0xFF1E8854),
        foregroundColor: Colors.white,
      ),
      body: friends.isEmpty
          ? const Center(
        child: Text(
          '현재 추가된 친구가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: friend.profileImageUrl != null
                  ? NetworkImage(friend.profileImageUrl!) as ImageProvider
                  : null,
              child: friend.profileImageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(friend.nickname),
            subtitle: Text(friend.major),
            trailing: TextButton(
              onPressed: () {
                // 친구 삭제 로직 (toggleFriend 사용)
                authProvider.toggleFriend(friend.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${friend.nickname}님을 친구 목록에서 삭제했습니다.')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          );
        },
      ),
    );
  }
}
