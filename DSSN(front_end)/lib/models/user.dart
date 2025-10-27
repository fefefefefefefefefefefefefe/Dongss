// lib/models/user.dart

class User {
  final String id;
  final String email; // ✅ 요청하신 이메일 필드 추가
  String nickname; // 💡 프로필 편집을 위해 final 제거
  final String major;
  final List<String> friends;
  final List<String> likedPosts; // 💡 좋아요 기능 구현을 위해 추가
  String? profileImageUrl;
  String? bio;

  User({
    required this.id,
    required this.email, // ✅ 생성자 매개변수에 추가
    required this.nickname,
    required this.major,
    required this.friends,
    required this.likedPosts,
    this.profileImageUrl,
    this.bio,
  });

  // copyWith 메서드: 객체의 불변성을 유지하며 특정 필드만 변경된 새 객체를 생성
  User copyWith({
    String? id,
    String? email,
    String? nickname,
    String? major,
    String? bio,
    String? profileImageUrl,
    List<String>? friends,
    List<String>? likedPosts, // 💡 copyWith에 likedPosts 추가
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      major: major ?? this.major,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      friends: friends ?? this.friends,
      likedPosts: likedPosts ?? this.likedPosts,
    );
  }
}
