// lib/screens/comment_screen.dart (새 파일 생성)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/screens/write_post_screen.dart';

class CommentScreen extends StatelessWidget {
  final Post post;

  const CommentScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('댓글'),
        backgroundColor: const Color(0xFF1E8854),
      ),
      // 댓글 목록과 입력창을 분리하기 위해 Column을 사용합니다.
      body: Column(
        children: [
          // 💡 1. 댓글 목록 표시 영역 (확장 가능하도록 Expanded 사용)
          Expanded(
            child: Consumer<PostProvider>(
              builder: (context, postProvider, child) {
                // 현재 게시물의 최신 상태 (특히 댓글 목록)를 가져옵니다.
                final currentPost = postProvider.posts.firstWhere(
                      (p) => p.id == post.id,
                  orElse: () => post,
                );

                if (currentPost.commentList.isEmpty) {
                  return const Center(
                    child: Text('첫 댓글을 작성해보세요.'),
                  );
                }

                // 최신 댓글이 위에 오도록 역순 정렬
                final comments = currentPost.commentList.reversed.toList();

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentTile(comment: comment);
                  },
                );
              },
            ),
          ),

          // 💡 2. 댓글 입력 필드
          _CommentInputField(postId: post.id),
        ],
      ),
    );
  }
}

// ------------------------------------
// 댓글 개별 항목 위젯
// ------------------------------------
class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  String _formatTime() {
    final difference = DateTime.now().difference(comment.createdAt);
    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    return '${comment.createdAt.year}.${comment.createdAt.month}.${comment.createdAt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 18,
        child: Icon(Icons.person, size: 20),
      ),
      title: Row(
        children: [
          Text(
            comment.author,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Text(comment.content),
    );
  }
}

// ------------------------------------
// 댓글 입력 위젯
// ------------------------------------
class _CommentInputField extends StatefulWidget {
  final String postId;

  const _CommentInputField({required this.postId});

  @override
  State<_CommentInputField> createState() => __CommentInputFieldState();
}

class __CommentInputFieldState extends State<_CommentInputField> {
  final _controller = TextEditingController();

  void _submitComment(BuildContext context) {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    final userId = authProvider.loggedInUser?.id;
    final userNickname = authProvider.loggedInUser?.nickname;

    if (userId == null || userNickname == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 댓글을 작성할 수 있습니다.')),
      );
      return;
    }

    // 💡 PostProvider에 댓글 추가 요청
    postProvider.addComment(
      postId: widget.postId,
      authorId: userId,
      author: userNickname,
      content: content,
    );

    _controller.clear(); // 입력 필드 초기화
    FocusScope.of(context).unfocus(); // 키보드 내리기
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF1E8854)),
            onPressed: () => _submitComment(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
