import 'package:flutter/material.dart';
import 'package:dong_story/models/user.dart';

class AuthProvider with ChangeNotifier {
  // -------------------------
  // 1. 상태 및 더미 데이터
  // -------------------------

  User? _loggedInUser;
  bool _isLoggedIn = false;

  // 💡 더미 사용자 목록 (검색 및 친구 추천용)
  final List<User> _allUsers = [
    // 성공적으로 로그인할 수 있는 사용자
    User(
        id: 'user1',
        email: 'stg1015@naver.com',
        nickname: '김동서',
        major: '컴퓨터소프트웨어학과',
        bio: '동서울대학교 개발 동아리 소속입니다.',
        friends: ['user2', 'user3', 'user4'],
        profileImageUrl: 'https://i.pravatar.cc/150?u=user1'),

    // 친구 추천용 사용자 (다른 학과)
    User(
        id: 'user2',
        email: 'lee@dsu.ac.kr',
        nickname: '이민재',
        major: '디자인학과',
        bio: '앱 디자이너를 꿈꿉니다.',
        friends: ['user1', 'user5'],
        profileImageUrl: 'https://i.pravatar.cc/150?u=user2'),

    // 친구 추천용 사용자 (같은 학과)
    User(
        id: 'user3',
        email: 'park@dsu.ac.kr',
        nickname: '박소현',
        major: '컴퓨터소프트웨어학과',
        bio: '함께 스터디 할 분 구해요!',
        friends: ['user1'],
        profileImageUrl: 'https://i.pravatar.cc/150?u=user3'),

    // 친구 추천용 사용자 (다른 학과)
    User(
        id: 'user4',
        email: 'choi@dsu.ac.kr',
        nickname: '최아영',
        major: '호텔외식조리과',
        bio: '요리하는 코더입니다.',
        friends: ['user1'],
        profileImageUrl: 'https://i.pravatar.cc/150?u=user4'),

    // 친구가 아닌 사용자 (추천 목록에 포함됨)
    User(
        id: 'user5',
        email: 'anon@dsu.ac.kr',
        nickname: '익명유저',
        major: '컴퓨터소프트웨어학과',
        bio: '안녕하세요.',
        friends: ['user2'],
        profileImageUrl: 'https://i.pravatar.cc/150?u=user5'),
  ];

  // -------------------------
  // 2. Public Getters (화면 접근용)
  // -------------------------

  bool get isLoggedIn => _isLoggedIn;
  User? get loggedInUser => _loggedInUser;
  String? get currentUser => _loggedInUser?.nickname;

  // ✅ ExploreScreen에서 필요했던 Getter 추가
  List<User> get allUsers => [..._allUsers];
  List<String> get allUserIds => _allUsers.map((u) => u.id).toList();

  // -------------------------
  // 3. 인증 로직
  // -------------------------

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // 로딩 시뮬레이션

    // 💡 하드코딩된 더미 로그인 성공 케이스
    if (email == 'stg1015@naver.com' && password == '75132') {
      _loggedInUser = _allUsers.firstWhere((user) => user.id == 'user1');
      _isLoggedIn = true;
      notifyListeners();
      return;
    }

    // 💡 실패 케이스
    throw Exception('로그인 정보가 일치하지 않거나 서버 오류입니다.');
  }

  Future<void> signup(String email, String password, String nickname) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // 로딩 시뮬레이션

    if (_allUsers.any((user) => user.email == email)) {
      throw Exception('이미 등록된 이메일입니다.');
    }

    // 💡 더미 회원가입 로직: 새로운 사용자를 목록에 추가 (실제는 DB 처리)
    final newUser = User(
      id: 'user${_allUsers.length + 1}',
      email: email,
      nickname: nickname,
      major: '자유전공학과', // SignupScreen의 기본값 반영
      bio: '새로 가입한 사용자입니다.',
      friends: [],
      profileImageUrl: null,
    );
    _allUsers.add(newUser);

    // 회원가입 후에는 로그인 화면으로 돌아가야 하므로, 상태 변경 없음
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

    _loggedInUser = _loggedInUser!.copyWith(
      nickname: nickname,
      bio: bio,
      profileImageUrl: profileImageUrl,
    );

    // 💡 _allUsers 목록에서도 업데이트 (다른 화면의 데이터 일관성 유지)
    final userIndex = _allUsers.indexWhere((u) => u.id == _loggedInUser!.id);
    if (userIndex != -1) {
      _allUsers[userIndex] = _loggedInUser!;
    }

    notifyListeners();
  }

  // -------------------------
  // 5. 친구 및 사용자 검색/관리
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