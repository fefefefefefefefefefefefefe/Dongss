// lib/providers/post_provider.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:dong_story/models/post.dart';

class PostProvider extends ChangeNotifier {
  // 💡 더미 게시물 데이터 (BoardType enum 사용)
  final List<Post> _posts = [
    Post(
      id: 'p1',
      authorId: 'u1',
      author: '나',
      title: '피드 일상 공유',
      content: '이것은 첫 번째 테스트 게시물의 내용입니다.',
      likes: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      comments: 3,
      boardType: BoardType.free,
      isFeedPost: true,
      commentList: const [],
    ),
    Post(
      id: 'p2',
      authorId: 'u2',
      author: '김민지',
      title: '점심 메뉴 추천 받아요!',
      content: '오늘 점심 뭐 드실 건가요? 동대문역 근처 맛집으로 추천 부탁드립니다.',
      likes: 22,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      comments: 7,
      boardType: BoardType.free,
      isFeedPost: true,
      commentList: const [],
    ),
    Post(
      id: 'p3',
      authorId: 'u3',
      author: '박준호 선배',
      title: '취업 관련 질문 받습니다',
      content: '전자공학과 후배님들, 궁금한 점 있으면 댓글 달아주세요.',
      likes: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      comments: 1,
      boardType: BoardType.question,
      isFeedPost: false,
      commentList: const [],
    ),
    Post(
      id: 'p4',
      authorId: 'u1',
      author: '나',
      title: '같이 스터디 할 사람?',
      content: '컴퓨터 스터디 같이 하실 분 구합니다. 스터디 모집!',
      likes: 30,
      createdAt: DateTime.now(),
      comments: 10,
      boardType: BoardType.information,
      isFeedPost: false,
      commentList: const [],
    ),
  ];

  // 모든 게시물을 반환
  List<Post> get posts => List.unmodifiable(_posts);

  // -------------------------
  // 1. 게시물 생성/수정/삭제 로직
  // -------------------------

  // ✅ [수정 및 필수] 커뮤니티 게시물 생성 함수
  //   - boardType을 인자로 받습니다.
  //   - isFeedPost를 false로 설정합니다.
  void createCommunityPost({
    required String authorId,
    required String authorNickname,
    required String content,
    required BoardType boardType, // ✅ BoardType enum 타입 사용
    String? title,
    String? imagePath,
  }) {
    final newPost = Post(
      id: 'p${_posts.length + 1}',
      authorId: authorId,
      author: authorNickname,
      title: title,
      content: content,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      boardType: boardType, // ✅ 인자로 받은 BoardType 사용
      isFeedPost: false,    // ✅ 커뮤니티 게시물
      likes: 0,
      comments: 0,
      commentList: const [],
    );
    _posts.insert(0, newPost);
    notifyListeners();
  }

  // ✅ [필수 추가] 피드 게시물 전용 생성 함수 (오류 해결 핵심!)
  //   - boardType을 인자로 받지 않습니다.
  //   - isFeedPost를 true로 설정합니다.
  void createFeedPost({
    required String authorId,
    required String authorNickname,
    required String content,
    String? title,
    String? imagePath,
  }) {
    final newPost = Post(
      id: 'p${_posts.length + 1}',
      authorId: authorId,
      author: authorNickname,
      title: title,
      content: content,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      boardType: BoardType.free, // 피드는 BoardType.free로 임시 지정
      isFeedPost: true,          // ✅ 피드 게시물
      likes: 0,
      comments: 0,
      commentList: const [],
    );
    _posts.insert(0, newPost);
    notifyListeners();
  }


  // [기존] 게시물 삭제 함수
  void deletePost(String postId) {
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }

  // -------------------------
  // 2. 좋아요 관리 로직
  // -------------------------

  // [기존] 좋아요 토글 함수 (예시)
  void toggleLike(String postId, {required bool isAdding}) {
    try {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final post = _posts[postIndex];

      if (isAdding) {
        _posts[postIndex] = post.copyWith(likes: post.likes + 1);
      } else {
        // 최소 0보다 작아지지 않도록 방지
        _posts[postIndex] = post.copyWith(likes: post.likes > 0 ? post.likes - 1 : 0);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('게시물 ID를 찾을 수 없습니다: $e');
    }
  }

  // 💡 [추가] 좋아요한 게시물 목록을 ID로 조회하는 함수 (ProfileScreen에서 사용)
  List<Post> getLikedPosts(List<String> postIds) {
    return _posts.where((post) => postIds.contains(post.id)).toList();
  }

  // -------------------------
  // 3. 댓글 관리 로직
  // -------------------------

  void addComment({
    required String postId,
    required String authorId,
    required String author,
    required String content,
  }) {
    try {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final post = _posts[postIndex];

      // 1. 새로운 Comment 객체 생성
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID
        authorId: authorId,
        author: author,
        content: content,
        createdAt: DateTime.now(),
      );

      // 2. 새로운 댓글 목록 및 댓글 수 업데이트
      final updatedCommentList = List<Comment>.from(post.commentList)..insert(0, newComment); // 최신 댓글 위로
      final updatedCommentsCount = post.comments + 1;

      // 3. Post 객체 업데이트 (copyWith 사용)
      _posts[postIndex] = post.copyWith(
        comments: updatedCommentsCount,
        commentList: updatedCommentList,
      );

      notifyListeners();

    } catch (e) {
      debugPrint('댓글 추가 중 오류 발생: $e');
    }
  }
}
