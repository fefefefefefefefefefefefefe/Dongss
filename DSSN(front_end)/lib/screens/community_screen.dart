// lib/screens/community_screen.dart

import 'package:flutter/material.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/screens/write_community_post_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            '커뮤니티',
            style: TextStyle(
              color: Color(0xFF1E8854),
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF1E8854),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF1E8854),
            tabs: [
              Tab(text: '자유게시판'),
              Tab(text: '질문게시판'),
              Tab(text: '정보공유'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostList(context, '자유게시판'),
            _buildPostList(context, '질문게시판'),
            _buildPostList(context, '정보공유'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WriteCommunityPostScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF66BB6A),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPostList(BuildContext context, String boardType) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final filteredPosts = postProvider.posts
            .where((post) => post.boardType == boardType && post.isFeedPost == false)
            .toList();

        return ListView.builder(
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return CommunityPostTile(
              title: post.title ?? '',
              content: post.content,
              author: post.author,
              likes: 5,
              comments: 2,
            );
          },
        );
      },
    );
  }
}

class CommunityPostTile extends StatelessWidget {
  final String title;
  final String content;
  final String author;
  final int likes;
  final int comments;

  const CommunityPostTile({
    super.key,
    required this.title,
    required this.content,
    required this.author,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '작성자: $author',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Text('5'), // 임시 좋아요 수
                  SizedBox(width: 8),
                  Icon(Icons.chat_bubble, size: 16, color: Colors.black54),
                  SizedBox(width: 4),
                  Text('2'), // 임시 댓글 수
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}