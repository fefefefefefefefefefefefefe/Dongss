// lib/screens/home_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/screens/community_screen.dart' show CommunityScreen;
import 'package:dong_story/screens/profile_screen.dart';
import 'package:dong_story/screens/chat_list_screen.dart';
import 'package:dong_story/screens/explore_screen.dart';
import 'package:dong_story/screens/home_feed_post.dart';
import 'package:dong_story/screens/comment_screen.dart'; // 💡 [추가] 댓글 화면 임포트
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const _FeedScreen(),
    const ExploreScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8854),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _FeedScreen extends StatelessWidget {
  const _FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    final feedPosts = postProvider.posts
        .where((post) => post.isFeedPost == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dong Story',
          style: TextStyle(
            color: Color(0xFF1E8854),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF1E8854)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeFeedPostScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
        ],
      ),
      body: feedPosts.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              '작성된 피드 게시글이 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text('오른쪽 위의 📝 버튼을 눌러 피드를 작성해보세요.'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: feedPosts.length,
        itemBuilder: (context, index) {
          final post = feedPosts[index];
          return _FeedPostCard(post: post);
        },
      ),
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  final Post post;

  const _FeedPostCard({
    super.key,
    required this.post,
  });

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {

  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isLiked = authProvider.hasLiked(widget.post.id);
  }

  void _toggleLike(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userId = authProvider.loggedInUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인해야 좋아요를 누를 수 있습니다.')),
      );
      return;
    }

    final bool isLiking = authProvider.toggleLikeStatus(widget.post.id);

    setState(() {
      _isLiked = isLiking;
    });

    postProvider.toggleLike(widget.post.id, isAdding: isLiking);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.year}.${timestamp.month}.${timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post; // Post 객체 사용

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person, size: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(post.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),

            if (post.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(post.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 💡 좋아요 버튼
                GestureDetector(
                  onTap: () => _toggleLike(context),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Consumer<PostProvider>(
                        builder: (context, provider, child) {
                          final currentPost = provider.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
                          return Text('${currentPost.likes}');
                        },
                      ),
                    ],
                  ),
                ),

                // 💡 [수정] 댓글 버튼: CommentScreen으로 이동
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(post: post), // Post 객체 전달
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 20, color: Colors.black54),
                      const SizedBox(width: 4),
                      // 💡 PostProvider를 통해 최신 댓글 수 표시
                      Consumer<PostProvider>(
                        builder: (context, provider, child) {
                          final currentPost = provider.posts.firstWhere((p) => p.id == post.id, orElse: () => post);
                          return Text('${currentPost.comments}');
                        },
                      ),
                    ],
                  ),
                ),

                // 공유 버튼
                const Icon(Icons.share, size: 20, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
