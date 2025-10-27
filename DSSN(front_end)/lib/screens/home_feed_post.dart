// lib/screens/home_feed_post.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/post.dart'; // BoardType 사용을 위해 필요
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.loggedInUser?.id;
    final currentUserNickname = authProvider.loggedInUser?.nickname;

    if (currentUserId == null || currentUserNickname == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인해 주세요.')),
      );
      return;
    }

    // 내용 또는 사진이 있어야 게시 가능
    if (_contentController.text.isNotEmpty || _imagePath != null) {

      // ✅ [수정] 피드 전용 함수 createFeedPost 호출 (PostProvider에 함수가 있다고 가정)
      Provider.of<PostProvider>(context, listen: false).createFeedPost(
        authorId: currentUserId,
        authorNickname: currentUserNickname,
        // 피드의 첫 줄을 제목으로 사용
        title: _contentController.text.split('\n').first.trim().isEmpty
            ? null // 내용이 없는 경우 null 전달
            : _contentController.text.split('\n').first.trim(),
        content: _contentController.text.trim(),
        imagePath: _imagePath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드에 게시물을 작성했습니다.')),
      );
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
        foregroundColor: const Color(0xFF1E8854), // 앱바 아이콘 색상
        backgroundColor: Colors.white, // 앱바 배경색
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text(
              '게시',
              style: TextStyle(color: Color(0xFF1E8854), fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                hintText: '지금 무슨 생각을 하고 있나요? (첫 줄은 제목으로 사용됩니다)',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),

            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
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
              icon: const Icon(Icons.photo_library, color: Color(0xFF1E8854)),
            ),
            if (_imagePath != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _imagePath = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
