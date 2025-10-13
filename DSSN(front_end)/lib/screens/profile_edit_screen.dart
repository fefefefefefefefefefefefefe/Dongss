// lib/screens/profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dong_story/providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    // 초기값 설정
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

  // 💡 더미 이미지 선택 함수 (실제는 image_picker 사용)
  void _selectImage() {
    setState(() {
      // 실제 앱에서는 갤러리나 카메라에서 이미지를 선택하고 업로드 URL을 가져와야 합니다.
      // 현재는 더미 URL로 토글합니다.
      if (_profileImageUrl == null) {
        _profileImageUrl = 'https://i.pravatar.cc/150?u=${DateTime.now().microsecondsSinceEpoch}';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 프로필 사진이 설정되었습니다.')),
        );
      } else {
        _profileImageUrl = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 사진이 제거되었습니다.')),
        );
      }
    });
  }

  void _saveProfile(AuthProvider authProvider) {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    authProvider.updateProfile(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      profileImageUrl: _profileImageUrl,
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
              onTap: _selectImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
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