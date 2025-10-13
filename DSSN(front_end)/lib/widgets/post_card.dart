import 'package:flutter/material.dart';
import 'package:dong_story/models/post.dart';
import 'package:dong_story/screens/comment_screen.dart';
import 'dart:io';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _likes = 0;
  bool _isLiked = false;

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _likes -= 1;
      } else {
        _likes += 1;
      }
      _isLiked = !_isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF66BB6A),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const Text(
                    '방금 전',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_vert),
            ],
          ),
          const SizedBox(height: 15),
          if (widget.post.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(widget.post.imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              widget.post.content,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
              Text('$_likes'),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentScreen(), // ✅ `const` 제거
                    ),
                  );
                },
              ),
              const Text('10'),
            ],
          ),
        ],
      ),
    );
  }
}