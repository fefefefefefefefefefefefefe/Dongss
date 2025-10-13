import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String? currentImagePath; // ✅ 이미지 경로 수신

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentBio,
    this.currentImagePath, // ✅ 생성자에 추가
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _newImagePath; // ✅ 새로운 이미지 경로 상태
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _bioController.text = widget.currentBio;
    _newImagePath = widget.currentImagePath; // ✅ 기존 이미지 경로로 초기화
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ✅ 갤러리에서 이미지 선택 함수
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newImagePath = pickedFile.path;
      });
    }
  }

  // 저장 버튼을 누르면 새 데이터를 이전 화면으로 반환합니다.
  void _saveProfile() {
    final updatedData = {
      'name': _nameController.text,
      'bio': _bioController.text,
      'imagePath': _newImagePath, // ✅ 이미지 경로를 함께 전달
    };
    Navigator.pop(context, updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('저장', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
        backgroundColor: const Color(0xFF1E8854),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ 1. 프로필 이미지 영역
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    // 이미지 경로가 있으면 파일을 표시하고, 없으면 기본 아이콘을 표시
                    backgroundImage: _newImagePath != null ? FileImage(File(_newImagePath!)) : null,
                    child: _newImagePath == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  // 카메라 아이콘 버튼
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. 닉네임 입력 필드
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // 3. 소개 입력 필드
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '소개',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}