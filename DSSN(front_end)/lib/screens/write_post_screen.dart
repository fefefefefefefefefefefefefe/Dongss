// lib/screens/write_post_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/models/post.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _imagePath;
  final picker = ImagePicker();

  // ✅ 게시판 선택 관련 상태 및 옵션 추가
  final List<String> _boardOptions = ['자유게시판', '질문게시판', '정보공유'];
  String _selectedBoard = '자유게시판';

  @override
  void dispose() {
    _titleController.dispose();
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
    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final newPost = Post(
        id: DateTime.now().toString(),
        author: '사용자',
        title: _titleController.text,
        content: _contentController.text,
        imagePath: _imagePath,
        timestamp: DateTime.now(),
        boardType: _selectedBoard, // ✅ 선택된 게시판 타입 전달
        isFeedPost: false,
      );

      Provider.of<PostProvider>(context, listen: false).addPost(newPost);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 글 작성'),
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
          crossAxisAlignment: CrossAxisAlignment.start, // 드롭다운 정렬을 위해 추가
          children: [
            // ✅ 0. 게시판 선택 드롭다운
            DropdownButton<String>(
              value: _selectedBoard,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple, fontSize: 16),
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBoard = newValue!;
                });
              },
              items: _boardOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // 1. 제목 입력 필드
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
            const Divider(height: 1), // 구분선

            // 2. 내용 입력 필드
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),

            if (_imagePath != null)
              Image.file(File(_imagePath!), fit: BoxFit.cover),
          ],
        ),
      ),
      bottomNavigationBar: Row(
        children: [
          IconButton(
            onPressed: _getImage,
            icon: const Icon(Icons.photo_library),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _imagePath = null;
              });
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}