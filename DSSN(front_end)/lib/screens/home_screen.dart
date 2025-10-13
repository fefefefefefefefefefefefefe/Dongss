// lib/screens/home_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart'; // 💡 이 줄이 꼭 있어야 합니다.
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/screens/community_screen.dart';
import 'package:dong_story/screens/profile_screen.dart';
import 'package:dong_story/screens/chat_list_screen.dart';
import 'package:dong_story/screens/explore_screen.dart';
import 'package:dong_story/screens/home_feed_post.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    _FeedScreen(),
    ExploreScreen(),
    CommunityScreen(),
    ProfileScreen(),
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
      appBar: AppBar( // ✅ 올바른 AppBar 사용
        title: const Text(
          'Dong Story',
          style: TextStyle(
            color: Color(0xFF1E8854),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [ // ✅ 'actions' 파라미터가 정확하게 정의되어 있습니다.
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
          return _FeedPostCard(
            author: post.author,
            content: post.content,
            imagePath: post.imagePath,
            timestamp: post.timestamp,
          );
        },
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  final String author;
  final String content;
  final String? imagePath;
  final DateTime timestamp;

  const _FeedPostCard({
    required this.author,
    required this.content,
    this.imagePath,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
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
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${timestamp.hour}시 ${timestamp.minute}분',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),

            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

            const Divider(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.favorite_border, size: 20),
                Icon(Icons.comment_outlined, size: 20),
                Icon(Icons.share, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}