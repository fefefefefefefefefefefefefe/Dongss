// lib/screens/profile_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/screens/settings_screen.dart';
import 'package:dong_story/screens/profile_edit_screen.dart';
import 'package:dong_story/screens/friend_recommend_screen.dart'; // 💡 [추가] 친구 추천 화면 임포트
import 'package:dong_story/screens/friends_management_screen.dart';

enum PostViewType { feed, community }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PostViewType _currentView = PostViewType.feed;

  List<Post> _getFilteredPosts(BuildContext context, AuthProvider auth, PostProvider post) {
    final currentUserId = auth.loggedInUser?.id;
    if (currentUserId == null) return [];

    final userPosts = post.posts
        .where((p) => p.authorId == currentUserId)
        .toList();

    if (_currentView == PostViewType.feed) {
      return userPosts.where((p) => p.isFeedPost == true).toList();
    } else { // PostViewType.community
      return userPosts.where((p) => p.isFeedPost == false).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.loggedInUser;

    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    final postsToShow = _getFilteredPosts(context, authProvider, postProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.nickname, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 정보 섹션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!) as ImageProvider
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.major,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          user.nickname,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(user.bio ?? '', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),

                  // 프로필 편집 아이콘 버튼
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.black54),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),

            // 2. 주요 액션 버튼 섹션 (친구, 추천)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ProfileActionButton(
                  icon: Icons.people_outline,
                  label: '친구 목록 (${user.friends.length})',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // 💡 파일 이름이 friends_management_screen.dart이므로 해당 클래스를 사용합니다.
                          builder: (context) => const FriendsManagementScreen()),);
                  },
                ),
                _ProfileActionButton(
                  icon: Icons.person_add_alt_outlined,
                  label: '친구 추천',
                  onTap: () {
                    // ✅ [수정] 친구 추천 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendRecommendScreen()),
                    );
                  },
                ),
              ],
            ),
            const Divider(),

            // 3. 작성 게시물 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '나의 작성 게시물',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            // 💡 탭 전환 버튼
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: '작성 게시물',
                    isSelected: _currentView == PostViewType.feed,
                    onTap: () {
                      setState(() {
                        _currentView = PostViewType.feed;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: '커뮤니티 글',
                    isSelected: _currentView == PostViewType.community,
                    onTap: () {
                      setState(() {
                        _currentView = PostViewType.community;
                      });
                    },
                  ),
                ),
              ],
            ),

            const Divider(height: 1),

            // 4. 게시물 목록
            if (postsToShow.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    _currentView == PostViewType.feed
                        ? '작성한 게시물이 없습니다.'
                        : '작성한 커뮤니티 게시물이 없습니다.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...postsToShow.map((post) => _MyPostCard(post: post)).toList(),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------
// 헬퍼 위젯: 액션 버튼
// ------------------------------------
class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF1E8854)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------
// 헬퍼 위젯: 탭 전환 버튼
// ------------------------------------
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1E8854) : Colors.grey.shade300,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1E8854) : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// 게시물 표시를 위한 임시 위젯
// ------------------------------------
class _MyPostCard extends StatelessWidget {
  final Post post;

  const _MyPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0.5,
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.content.length > 50
                    ? '${post.content.substring(0, 50)}...'
                    : post.content,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
            ],
          ),

          subtitle: Row(
            children: [
              const Icon(Icons.favorite_border, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text('${post.likes}', style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(width: 12),
              const Icon(Icons.comment_outlined, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text('${post.comments}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          ),

          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('게시물 [${post.id}] 상세 보기')),
            );
          },
        ),
      ),
    );
  }
}
