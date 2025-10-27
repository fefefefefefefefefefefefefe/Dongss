// lib/screens/post_create_screen.dart (혹은 write_community_post_screen.dart의 내용을 이 코드로 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/post_provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:dong_story/models/post.dart'; // BoardType enum 사용을 위해 임포트
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ✅ 클래스 이름을 PostCreateScreen으로 통일하고, 초기 BoardType을 받도록 수정
class PostCreateScreen extends StatefulWidget {
  final BoardType initialBoardType;

  const PostCreateScreen({super.key, required this.initialBoardType});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // 폼 검증을 위한 키 추가

  String? _imagePath;
  final picker = ImagePicker();

  // ✅ 게시판 옵션을 BoardType enum 목록으로 변경 (3가지로 간소화된 구조 반영)
  final List<BoardType> _boardOptions = [
    BoardType.free,
    BoardType.question,
    BoardType.information,
  ];

  // ✅ 선택된 게시판 타입을 BoardType으로 변경
  BoardType? _selectedBoardType;

  @override
  void initState() {
    super.initState();
    // 초기 게시판 타입 설정
    _selectedBoardType = widget.initialBoardType;
  }

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    final currentUser = authProvider.loggedInUser;

    if (currentUser == null || _selectedBoardType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요하거나 게시판이 선택되지 않았습니다.')),
      );
      return;
    }

    if (_contentController.text.isNotEmpty) {
      // ✅ [수정] createPost 대신 createCommunityPost 함수 호출 및 BoardType 인자 전달
      postProvider.createCommunityPost(
        authorId: currentUser.id,
        authorNickname: currentUser.nickname,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        content: _contentController.text.trim(),
        imagePath: _imagePath,
        boardType: _selectedBoardType!, // ✅ BoardType enum 값 전달
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물이 ${_selectedBoardType!.displayName}에 작성되었습니다.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용은 필수 입력 사항입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 글 작성'),
        backgroundColor: const Color(0xFF1E8854),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text('게시', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ DropdownButton을 DropdownButtonFormField로 변경하고 BoardType 사용
              DropdownButtonFormField<BoardType>(
                decoration: const InputDecoration(
                  labelText: '게시판 선택',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                value: _selectedBoardType,
                icon: const Icon(Icons.arrow_downward, color: Color(0xFF1E8854)),
                elevation: 16,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                items: _boardOptions.map((board) {
                  return DropdownMenuItem(
                    value: board,
                    child: Text(board.displayName), // BoardType.displayName 사용
                  );
                }).toList(),
                onChanged: (BoardType? newValue) {
                  setState(() {
                    _selectedBoardType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '게시판을 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 제목 입력 필드
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요 (선택)',
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
              ),
              const Divider(height: 1),

              // 내용 입력 필드
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요',
                  border: InputBorder.none,
                ),
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '내용은 필수 입력 사항입니다.';
                  }
                  return null;
                },
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
