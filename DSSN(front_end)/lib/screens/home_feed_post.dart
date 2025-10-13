// lib/screens/home_feed_post.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeFeedPostScreen extends StatefulWidget {
  const HomeFeedPostScreen({super.key});

  @override
  State<HomeFeedPostScreen> createState() => _HomeFeedPostScreenState();
}

class _HomeFeedPostScreenState extends State<HomeFeedPostScreen> {
  final _contentController = TextEditingController();
  String? _imagePath;
  final picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imagePath = pickedFile.path;
      }
    });
  }

  void _submitPost() {
    if (_contentController.text.isNotEmpty || _imagePath != null) {
      final newPost = Post(
        id: DateTime.now().toString(),
        author: '사용자',
        content: _contentController.text,
        imagePath: _imagePath,
        timestamp: DateTime.now(),
        isFeedPost: true,
        boardType: null,
      );

      Provider.of<PostProvider>(context, listen: false).addPost(newPost);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용이나 사진을 추가해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 피드 작성'),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text('게시'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '지금 무슨 생각을 하고 있나요?',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),

            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _getImage,
              icon: const Icon(Icons.photo_library),
            ),
            if (_imagePath != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _imagePath = null;
                  });
                },
                icon: const Icon(Icons.delete),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}