// lib/screens/profile_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/user.dart';
import 'package:dong_story/screens/friends_management_screen.dart';
import 'package:dong_story/screens/profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userNickname = authProvider.currentUser ?? '비회원';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: null,
              background: Container(
                color: const Color(0xFF1E8854),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 60, color: Color(0xFF1E8854)),
                      ),
                      const SizedBox(height: 10),
                      // 닉네임을 프로필 사진 아래에 배치
                      Text(
                        userNickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const _ProfileContent(),
                // 오버플로우 최종 방지용 여유 공간
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  Widget _buildEditShareButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(), // 💡 연결
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('프로필 편집'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          // 💡 "친구 관리" 버튼으로 변경
          child: OutlinedButton.icon(
            onPressed: () {
              // FriendsManagementScreen으로 이동
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FriendsManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.group, size: 18),
            label: const Text('친구 관리'), // 💡 텍스트 변경
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.loggedInUser;

        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('로그인 후 이용 가능합니다.')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${user.major} 학과',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildEditShareButtons(context),
                ],
              ),
            ),

            const Divider(),

            _RecommendedFriendsSection(authProvider: authProvider),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('나의 활동'),
                  _buildActivityButtons(context),
                  const Divider(),
                  _buildSectionTitle('작성한 게시물'),
                  _buildPostGrid(context),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        authProvider.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(200, 45),
                      ),
                      child: const Text('로그아웃', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActivityButtons(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActivityItem(Icons.thumb_up, '좋아요'),
        _ActivityItem(Icons.bookmark, '저장됨'),
        _ActivityItem(Icons.comment, '댓글'),
      ],
    );
  }

  Widget _buildPostGrid(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final posts = postProvider.posts;

        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: Text('작성된 게시물이 없습니다.'),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    post.title ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActivityItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: const Color(0xFF1E8854)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}

class _RecommendedFriendsSection extends StatelessWidget {
  final AuthProvider authProvider;

  const _RecommendedFriendsSection({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final recommendedUsers = authProvider.recommendedFriends;

    if (recommendedUsers.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '친구 추천',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedUsers.length,
              itemBuilder: (context, index) {
                final user = recommendedUsers[index];
                return _FriendRecommendationCard(
                  user: user,
                  authProvider: authProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRecommendationCard extends StatelessWidget {
  final User user;
  final AuthProvider authProvider;

  const _FriendRecommendationCard({required this.user, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final isSameMajor = user.major == authProvider.loggedInUser?.major;
    final isFriend = authProvider.isFriend(user.id);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: isSameMajor ? Colors.green.shade50 : Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 20,
            child: Icon(Icons.person),
          ),
          const SizedBox(height: 5),
          Text(
            user.nickname,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            isSameMajor ? '같은 학과' : user.major,
            style: TextStyle(fontSize: 11, color: isSameMajor ? Colors.green.shade700 : Colors.grey),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 25,
            child: ElevatedButton(
              onPressed: () {
                final action = isFriend ? '친구 끊기' : '친구 추가';

                // 친구 상태 토글
                authProvider.toggleFriend(user.id);

                // 💡 친구 추가/끊기 시 스낵바 메시지 표시
                String message;
                if (!isFriend) {
                  message = '${user.nickname}님에게 친구를 요청했습니다.';
                } else {
                  message = '${user.nickname}님과의 친구 관계를 취소했습니다.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFriend ? Colors.grey : const Color(0xFF1E8854),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
              ),
              child: Text(
                isFriend ? '친구 끊기' : '친구 추가',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}