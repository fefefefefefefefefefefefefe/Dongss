// lib/models/post.dart (전체 덮어쓰기)

// 💡 [추가] 게시판 타입을 정의하는 enum
enum BoardType {
  // ✅ 커뮤니티 게시판 3가지로 간소화
  free('자유게시판'),
  question('질문게시판'),
  information('정보공유 게시판');

  final String displayName;
  const BoardType(this.displayName);
}

// 💡 [새로운 모델] 댓글을 표현하는 Comment 클래스 정의
class Comment {
  final String id;
  final String authorId;
  final String author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.authorId,
    required this.author,
    required this.content,
    required this.createdAt,
  });
}


class Post {
  final String id;
  final String authorId; // 게시물 작성자 ID
  final String author;
  final String? title;
  final String content;
  final String? imagePath;
  final DateTime createdAt;
  int likes;
  int comments; // 댓글 수

  // ✅ [수정] boardType의 타입을 String에서 BoardType enum으로 변경
  final BoardType boardType;

  final bool isFeedPost;

  // 💡 댓글 목록 필드
  final List<Comment> commentList;

  Post({
    required this.id,
    required this.authorId,
    required this.author,
    this.title,
    required this.content,
    this.imagePath,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    // ✅ [수정] 생성자에서도 BoardType 타입을 사용
    required this.boardType,
    required this.isFeedPost,
    this.commentList = const [],
  });

  // 💡 copyWith 메서드
  Post copyWith({
    String? id,
    String? authorId,
    String? author,
    String? title,
    String? content,
    String? imagePath,
    DateTime? createdAt,
    int? likes,
    int? comments,
    // ✅ [수정] copyWith에서도 BoardType 타입을 사용
    BoardType? boardType,
    bool? isFeedPost,
    List<Comment>? commentList,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      boardType: boardType ?? this.boardType,
      isFeedPost: isFeedPost ?? this.isFeedPost,
      commentList: commentList ?? this.commentList,
    );
  }
}
