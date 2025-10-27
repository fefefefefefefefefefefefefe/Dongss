// lib/screens/profile_edit_screen.dart (전체 덮어쓰기)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택 패키지
import 'dart:io'; // File 객체 사용을 위해 임포트

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  // 기존 프로필 이미지 URL
  String? _profileImageUrl;

  // ✅ [수정] 새로 선택된 이미지의 파일 경로 (로컬 경로)
  String? _newImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).loggedInUser;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _bioController.text = user.bio ?? '';
      _profileImageUrl = user.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ✅ [추가/수정] 갤러리를 열어 이미지 파일을 선택하는 함수
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        // 새로 선택된 이미지의 로컬 경로를 저장
        _newImagePath = pickedFile.path;
      }
    });
  }

  // ✅ [수정] 프로필 저장 함수
  void _saveProfile(AuthProvider authProvider) {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    // 💡 AuthProvider의 updateProfile 함수에 newImagePath를 전달하도록 변경해야 합니다.
    // 현재는 updateProfile이 profileImageUrl만 받으므로, 임시로 updateProfileWithImage로 가정하거나,
    // 사용자가 updateProfile 함수를 newImagePath를 받도록 수정해야 합니다.

    // 📢 (주의) updateProfile 함수가 아래와 같이 변경되어야 오류 없이 작동합니다.
    // authProvider.updateProfile(nickname, bio, profileImageUrl, newImagePath)

    authProvider.updateProfile(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      // 💡 [수정] 새로운 이미지가 있다면 로컬 경로를 전달하고, 없다면 기존 URL을 전달합니다.
      profileImageUrl: _newImagePath ?? _profileImageUrl,
      // ❌ [해당 없음] 서버에 업로드하는 로직이 없어, 현재는 로컬 경로를 URL 자리에 임시로 넣었습니다.
      // 실제로는 _newImagePath가 있으면 이를 서버에 업로드 후, 반환된 URL을 profileImageUrl에 넣어야 합니다.
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 성공적으로 저장되었습니다.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        backgroundColor: const Color(0xFF1E8854),
        actions: [
          TextButton(
            onPressed: () => _saveProfile(authProvider),
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 💡 프로필 사진 영역
            GestureDetector(
              onTap: _pickImage, // ✅ [수정] 이미지 선택 함수 연결
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    // ✅ [수정] _newImagePath가 있으면 로컬 FileImage 사용, 아니면 기존 NetworkImage 사용
                    backgroundImage: _newImagePath != null
                        ? FileImage(File(_newImagePath!))
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null) as ImageProvider<Object>?,
                    child: _newImagePath == null && _profileImageUrl == null
                        ? const Icon(Icons.person, size: 70, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E8854),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 💡 닉네임 입력 필드
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                hintText: '새로운 닉네임을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // 💡 소개글 입력 필드
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: '소개글',
                hintText: '자신을 소개해보세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 150,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
