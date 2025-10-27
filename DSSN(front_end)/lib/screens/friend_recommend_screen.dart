// lib/screens/friend_recommend_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/user.dart';

class FriendRecommendScreen extends StatelessWidget {
  const FriendRecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // 💡 AuthProvider의 정렬된 추천 목록 getter 사용
    final recommendedUsers = authProvider.recommendedFriends;
    final currentUserMajor = authProvider.loggedInUser?.major;

    // 첫 번째로 나오는 사용자가 현재 사용자와 같은 과인지 확인 (헤더 구분을 위해)
    final firstOtherMajorIndex = recommendedUsers.indexWhere((user) => user.major != currentUserMajor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 추천'),
        backgroundColor: const Color(0xFF1E8854),
        foregroundColor: Colors.white,
      ),
      body: recommendedUsers.isEmpty
          ? const Center(
        child: Text(
          '현재 추천할 친구가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: recommendedUsers.length,
        itemBuilder: (context, index) {
          final user = recommendedUsers[index];
          final isSameMajor = user.major == currentUserMajor;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그룹 헤더 표시 로직
              if (index == 0)
                _buildHeader(context, isSameMajor ? '같은 학과 (${currentUserMajor})' : '다른 학과 사용자'),

              // 다른 학과 사용자가 시작될 때만 헤더 표시
              if (index == firstOtherMajorIndex && index > 0)
                _buildHeader(context, '다른 학과 사용자'),

              _RecommendedUserTile(user: user, authProvider: authProvider, isSameMajor: isSameMajor),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }
}

// ------------------------------------
// 헬퍼 위젯: 추천 사용자 목록 타일
// ------------------------------------
class _RecommendedUserTile extends StatelessWidget {
  final User user;
  final AuthProvider authProvider;
  final bool isSameMajor;

  const _RecommendedUserTile({
    required this.user,
    required this.authProvider,
    required this.isSameMajor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!) as ImageProvider
            : null,
        child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.nickname),
      subtitle: Row(
        children: [
          Text(user.major),
          if (isSameMajor)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.school, size: 16, color: Color(0xFF1E8854)),
            ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () {
          // 💡 친구 추가 로직 (toggleFriend 사용)
          authProvider.toggleFriend(user.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.nickname}님을 친구로 추가했습니다.')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E8854),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: const Text('친구 추가'),
      ),
    );
  }
}
