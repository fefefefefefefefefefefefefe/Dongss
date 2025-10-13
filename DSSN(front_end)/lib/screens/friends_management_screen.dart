// lib/screens/friends_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';

class FriendsManagementScreen extends StatelessWidget {
  const FriendsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.loggedInUser;

    // 더미 사용자 목록에서 현재 친구 목록을 ID를 통해 필터링합니다.
    final List<String> friendIds = currentUser?.friends ?? [];

    // 현재 AuthProvider의 _allUsers 목록에 접근할 수 없으므로,
    // 친구 ID만 표시하는 간단한 목록을 만들겠습니다.
    // 실제 앱에서는 AuthProvider에 친구 정보를 가져오는 함수가 필요합니다.

    // 💡 AuthProvider에서 모든 사용자 목록을 가져와 친구 정보를 만듭니다.
    final List<String> allUserIds = authProvider.allUserIds;

    final List<Map<String, String>> friendsInfo = allUserIds
        .where((id) => friendIds.contains(id))
        .map((id) {
      final user = authProvider.getUserById(id); // 유저 정보를 가져오는 함수 필요
      return {
        'id': user?.id ?? id,
        'nickname': user?.nickname ?? '알 수 없음',
        'major': user?.major ?? '알 수 없음',
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: friendsInfo.isEmpty
          ? const Center(
        child: Text(
          '현재 추가된 친구가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: friendsInfo.length,
        itemBuilder: (context, index) {
          final friend = friendsInfo[index];
          final friendId = friend['id']!;
          final friendNickname = friend['nickname']!;

          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(friendNickname),
            subtitle: Text(friend['major']!),
            trailing: TextButton(
              onPressed: () {
                // 친구 삭제 로직
                authProvider.toggleFriend(friendId);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${friendNickname}님을 친구 목록에서 삭제했습니다.')),
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