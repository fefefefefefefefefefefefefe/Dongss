import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/models/user.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/screens/profile_screen.dart'; // 프로필 화면 연결을 위해 임시 추가 (MainScreen에서 ProfileScreen으로 연결되어야 함)

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 검색어 변경 시 상태 업데이트
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '사용자, 게시물을 검색하세요...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1E8854)),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onSubmitted: (value) {
                  // 검색어 제출 시 키보드 숨기기
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF1E8854),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF1E8854),
            tabs: [
              Tab(text: '사용자'),
              Tab(text: '게시물'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserSearchResults(context),
            _buildPostSearchResults(context),
          ],
        ),
      ),
    );
  }

  // --- 사용자 검색 결과 탭 ---
  Widget _buildUserSearchResults(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (_searchQuery.isEmpty) {
          return const Center(child: Text('닉네임이나 전공으로 검색할 수 있습니다.'));
        }

        final List<User> allUsers = authProvider.allUsers;
        final filteredUsers = allUsers.where((user) {
          return user.nickname.toLowerCase().contains(_searchQuery) ||
              (user.major.toLowerCase().contains(_searchQuery));
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];

            // 현재 로그인된 사용자는 목록에서 제외
            if (user.id == authProvider.loggedInUser?.id) return const SizedBox.shrink();

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.major),
              trailing: _buildFriendButton(authProvider, user),
              onTap: () {
                // TODO: 다른 사용자의 프로필 화면으로 이동 (현재 ProfileScreen은 본인 전용이므로 수정 필요)
              },
            );
          },
        );
      },
    );
  }

  // --- 친구 추가/끊기 버튼 위젯 ---
  Widget _buildFriendButton(AuthProvider authProvider, User user) {
    final isFriend = authProvider.isFriend(user.id);
    final buttonText = isFriend ? '친구 끊기' : '친구 추가';
    final buttonColor = isFriend ? Colors.grey.shade400 : const Color(0xFF1E8854);

    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: () {
          authProvider.toggleFriend(user.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.nickname}님을 ${isFriend ? '친구 목록에서 삭제' : '친구로 추가'}했습니다.')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  // --- 게시물 검색 결과 탭 ---
  Widget _buildPostSearchResults(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (_searchQuery.isEmpty) {
          return const Center(child: Text('제목 또는 내용으로 검색할 수 있습니다.'));
        }

        final List<Post> allPosts = postProvider.posts;
        final filteredPosts = allPosts.where((post) {
          final contentMatch = post.content.toLowerCase().contains(_searchQuery);
          final titleMatch = post.title != null && post.title!.toLowerCase().contains(_searchQuery);
          return contentMatch || titleMatch;
        }).toList();

        if (filteredPosts.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }

        return ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return ListTile(
              leading: const Icon(Icons.article),
              title: Text(post.title ?? post.content.substring(0, post.content.length > 20 ? 20 : post.content.length) + '...'),
              subtitle: Text('작성자: ${post.author}'),
              onTap: () {
                // TODO: 게시물 상세 화면으로 이동
              },
            );
          },
        );
      },
    );
  }
}