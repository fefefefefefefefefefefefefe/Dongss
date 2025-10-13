// lib/models/post.dart

class Post {
  final String id;
  final String author;
  final String? title;
  final String content;
  final String? imagePath;
  final DateTime timestamp;
  final String? boardType;
  final bool isFeedPost;

  const Post({
    required this.id,
    required this.author,
    this.title,
    required this.content,
    this.imagePath,
    required this.timestamp,
    this.boardType,
    required this.isFeedPost,
  });
}