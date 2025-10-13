class User {
  final String id;
  final String email; // ✅ 1. 이메일 필드 추가
  final String nickname;
  final String major;
  final String? bio;
  final String? profileImageUrl;
  final List<String> friends;

  const User({
    required this.id,
    required this.email, // ✅ 2. 생성자 매개변수에 추가
    required this.nickname,
    required this.major,
    this.bio,
    this.profileImageUrl,
    required this.friends,
  });

  // copyWith 메서드에도 email을 추가해야 합니다.
  User copyWith({
    String? id,
    String? email, // ✅ 3. copyWith 매개변수에 추가
    String? nickname,
    String? major,
    String? bio,
    String? profileImageUrl,
    List<String>? friends,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email, // ✅ 4. copyWith 구현
      nickname: nickname ?? this.nickname,
      major: major ?? this.major,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      friends: friends ?? this.friends,
    );
  }
}