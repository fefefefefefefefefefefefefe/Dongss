// lib/providers/post_provider.dart

import 'package:flutter/material.dart';
import 'package:dong_story/models/post.dart';

class PostProvider extends ChangeNotifier {
  final List<Post> _posts = [];

  List<Post> get posts => _posts;

  void addPost(Post post) {
    _posts.insert(0, post); // 최신 글이 항상 맨 위로 오도록 0번째 인덱스에 삽입
    notifyListeners();
  }
}
