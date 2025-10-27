// lib/screens/community_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/screens/write_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // 💡 [수정] 현재 선택된 게시판 타입 (기본: 자유게시판)
  BoardType _currentBoard = BoardType.free;

  // 💡 [수정] 탭에 표시할 게시판 목록을 BoardType enum에서 가져옵니다.
  final List<BoardType> _boardTypes = [
    BoardType.free,
    BoardType.question,
    BoardType.information,
  ];

  // 선택된 게시판 타입에 해당하는 게시물만 필터링
  List<Post> _getFilteredPosts(PostProvider postProvider) {
    return postProvider.posts
        .where((p) => p.boardType == _currentBoard && p.isFeedPost == false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final posts = _getFilteredPosts(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 💡 [추가] 게시물 작성 버튼 (기존에 있었다고 가정)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E8854)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // WritePostScreen은 BoardType을 인자로 받지 않기로 했으므로,
                  // 간단하게 const 생성자로 화면을 엽니다.
                    builder: (context) => const WritePostScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 게시판 탭 선택 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _boardTypes.map((boardType) {
                return _BoardTabButton(
                  label: boardType.displayName,
                  isSelected: _currentBoard == boardType,
                  onTap: () {
                    setState(() {
                      _currentBoard = boardType;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // 2. 게시물 목록
          Expanded(
            child: posts.isEmpty
                ? Center(
              child: Text(
                '${_currentBoard.displayName}에 작성된 글이 없습니다.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _PostCard(post: posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------
// 헬퍼 위젯: 게시판 탭 버튼
// ------------------------------------
class _BoardTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoardTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E8854) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------
// 헬퍼 위젯: 게시물 카드 표시
// ------------------------------------
class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          // 💡 [수정] 제목이 없다고 가정하고 내용을 잘라서 표시
          post.content.length > 50 ? '${post.content.substring(0, 50)}...' : post.content,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${post.boardType.displayName}', // 게시판 이름은 카드에 표시
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              Row(
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
            ],
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${post.boardType.displayName}의 상세 글로 이동')),
          );
        },
      ),
    );
  }
}
