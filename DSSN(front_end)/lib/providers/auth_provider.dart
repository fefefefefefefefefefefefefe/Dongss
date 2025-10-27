// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:dong_story/models/user.dart';

class AuthProvider with ChangeNotifier {
  // -------------------------
  // 1. 상태 및 더미 데이터
  // -------------------------

  User? _loggedInUser;
  bool _isLoggedIn = false;

  // 💡 더미 사용자 목록: likedPosts 필드가 추가됨
  final List<User> _allUsers = [
    // 성공적으로 로그인할 수 있는 사용자
    User(
      id: 'user1',
      email: 'admin@dsu.ac.kr', // 💡 로그인 테스트 계정 ('admin@dsu.ac.kr' / 'admin')
      nickname: '나',
      major: '컴퓨터소프트웨어학과',
      bio: '동서울대학교 개발 동아리 소속입니다.',
      friends: ['user2', 'user3', 'user4'],
      likedPosts: ['p2', 'p4'], // 💡 좋아요한 게시물 ID 추가 (테스트용)
      profileImageUrl: 'https://i.pravatar.cc/150?u=user1',
    ),

    // 친구 추천용 사용자 (다른 학과)
    User(
      id: 'user2',
      email: 'lee@dsu.ac.kr',
      nickname: '이민재',
      major: '디자인학과',
      bio: '앱 디자이너를 꿈꿉니다.',
      friends: ['user1', 'user5'],
      likedPosts: ['p1'],
      profileImageUrl: 'https://i.pravatar.cc/150?u=user2',
    ),

    // 친구 추천용 사용자 (같은 학과)
    User(
      id: 'user3',
      email: 'park@dsu.ac.kr',
      nickname: '박소현',
      major: '컴퓨터소프트웨어학과',
      bio: '함께 스터디 할 분 구해요!',
      friends: ['user1'],
      likedPosts: [],
      profileImageUrl: 'https://i.pravatar.cc/150?u=user3',
    ),

    // 친구 추천용 사용자 (다른 학과)
    User(
      id: 'user4',
      email: 'choi@dsu.ac.kr',
      nickname: '최아영',
      major: '호텔외식조리과',
      bio: '요리하는 코더입니다.',
      friends: ['user1'],
      likedPosts: [],
      profileImageUrl: 'https://i.pravatar.cc/150?u=user4',
    ),

    // 친구가 아닌 사용자 (추천 목록에 포함됨)
    User(
      id: 'user5',
      email: 'anon@dsu.ac.kr',
      nickname: '익명유저',
      major: '컴퓨터소프트웨어학과',
      bio: '안녕하세요.',
      friends: ['user2'],
      likedPosts: ['p3'],
      profileImageUrl: 'https://i.pravatar.cc/150?u=user5',
    ),
  ];

  // -------------------------
  // 2. Public Getters (화면 접근용)
  // -------------------------

  bool get isLoggedIn => _isLoggedIn;
  User? get loggedInUser => _loggedInUser;
  String? get currentUser => _loggedInUser?.nickname;

  List<User> get allUsers => [..._allUsers];
  List<String> get allUserIds => _allUsers.map((u) => u.id).toList();

  // -------------------------
  // 3. 인증 로직
  // -------------------------

  // 💡 앱 시작 시 자동 로그인 (선택 사항)
  // AuthProvider() {
  //   _loggedInUser = _allUsers.firstWhere((user) => user.id == 'user1');
  //   _isLoggedIn = true;
  // }

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // 💡 더미 로그인 성공 케이스: admin 계정 사용
    if (email == 'admin@dsu.ac.kr' && password == 'admin') {
      _loggedInUser = _allUsers.firstWhere((user) => user.id == 'user1');
      _isLoggedIn = true;
      notifyListeners();
      return;
    }

    // 💡 실패 케이스
    throw Exception('로그인 정보가 일치하지 않거나 서버 오류입니다.');
  }

  Future<void> signup(String email, String password, String nickname) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_allUsers.any((user) => user.email == email)) {
      throw Exception('이미 등록된 이메일입니다.');
    }

    // 💡 더미 회원가입 로직: 새로운 사용자를 목록에 추가 (실제는 DB 처리)
    final newUser = User(
      id: 'user${_allUsers.length + 1}',
      email: email,
      nickname: nickname,
      major: '자유전공학과',
      bio: '새로 가입한 사용자입니다.',
      friends: [],
      likedPosts: [], // 💡 새 사용자에게 빈 목록 할당
      profileImageUrl: null,
    );
    _allUsers.add(newUser);

    return;
  }

  void logout() {
    _loggedInUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // -------------------------
  // 4. 프로필 관리 로직
  // -------------------------

  void updateProfile({
    required String nickname,
    required String bio,
    required String? profileImageUrl,
  }) {
    if (_loggedInUser == null) return;

    // 💡 copyWith를 사용하여 프로필 정보 업데이트
    _loggedInUser = _loggedInUser!.copyWith(
      nickname: nickname,
      bio: bio,
      profileImageUrl: profileImageUrl,
      // likedPosts와 friends는 기존 값을 유지
    );

    // _allUsers 목록에서도 업데이트 (다른 화면의 데이터 일관성 유지)
    final userIndex = _allUsers.indexWhere((u) => u.id == _loggedInUser!.id);
    if (userIndex != -1) {
      _allUsers[userIndex] = _loggedInUser!;
    }

    notifyListeners();
  }

  // -------------------------
  // 5. 좋아요 상태 관리 로직 (Like Status)
  // -------------------------

  // 💡 [추가] 좋아요 상태 토글 및 User 모델 업데이트
  bool toggleLikeStatus(String postId) {
    if (_loggedInUser == null) return false;

    final currentLikedPosts = List<String>.from(_loggedInUser!.likedPosts);
    bool isLiking;

    if (currentLikedPosts.contains(postId)) {
      // 좋아요 취소
      currentLikedPosts.remove(postId);
      isLiking = false;
    } else {
      // 좋아요 추가
      currentLikedPosts.add(postId);
      isLiking = true;

    }

    // 💡 copyWith를 사용하여 새 상태로 User 객체 업데이트
    _loggedInUser = _loggedInUser!.copyWith(likedPosts: currentLikedPosts);

    // _allUsers 목록 업데이트
    final userIndex = _allUsers.indexWhere((u) => u.id == _loggedInUser!.id);
    if (userIndex != -1) {
      _allUsers[userIndex] = _loggedInUser!;
    }

    notifyListeners();
    return isLiking;
  }

  // 💡 [추가] 특정 게시물을 좋아요 했는지 확인
  bool hasLiked(String postId) {
    return _loggedInUser?.likedPosts.contains(postId) ?? false;
  }


  // -------------------------
  // 6. 친구 및 사용자 검색/관리
  // -------------------------

  // ID로 사용자 정보를 가져오는 헬퍼 함수
  User? getUserById(String id) {
    try {
      return _allUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // 친구 상태 확인
  bool isFriend(String userId) {
    return _loggedInUser?.friends.contains(userId) ?? false;
  }

  // 친구 추가/삭제 (toggle) 로직
  void toggleFriend(String targetUserId) {
    if (_loggedInUser == null) return;

    final targetUser = getUserById(targetUserId);
    if (targetUser == null) return;

    final currentFriends = List<String>.from(_loggedInUser!.friends);
    final targetFriends = List<String>.from(targetUser.friends);

    if (isFriend(targetUserId)) {
      // 삭제
      currentFriends.remove(targetUserId);
      targetFriends.remove(_loggedInUser!.id);
    } else {
      // 추가
      currentFriends.add(targetUserId);
      targetFriends.add(_loggedInUser!.id);
    }

    // 💡 양방향 업데이트 적용
    updateFriendsList(_loggedInUser!.id, currentFriends);
    updateFriendsList(targetUserId, targetFriends);

    notifyListeners();
  }

  // 내부에서만 사용되는 실제 친구 목록 업데이트 함수
  void updateFriendsList(String userId, List<String> newFriends) {
    final userIndex = _allUsers.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      _allUsers[userIndex] = _allUsers[userIndex].copyWith(friends: newFriends);
      if (userId == _loggedInUser?.id) {
        _loggedInUser = _allUsers[userIndex]; // 로그인된 사용자 상태도 업데이트
      }
    }
  }

  // 친구 추천 로직 (ProfileScreen에서 사용)
  List<User> get recommendedFriends {
    if (_loggedInUser == null) return [];

    final loggedInUserId = _loggedInUser!.id;
    final loggedInUserMajor = _loggedInUser!.major;
    final currentUserFriends = _loggedInUser!.friends;

    final nonFriends = _allUsers
        .where((user) =>
    user.id != loggedInUserId &&
        !currentUserFriends.contains(user.id))
        .toList();

    // 1. 같은 학과 우선순위로 정렬
    nonFriends.sort((a, b) {
      final aSameMajor = a.major == loggedInUserMajor;
      final bSameMajor = b.major == loggedInUserMajor;
      if (aSameMajor && !bSameMajor) return -1;
      if (!aSameMajor && bSameMajor) return 1;
      return 0;
    });

    // 상위 5명만 추천
    return nonFriends.take(5).toList();
  }
}
