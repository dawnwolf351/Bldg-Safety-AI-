// 데이터의 구조를 정의하는 Model 클래스입니다.
// MVVM 패턴에서 'Model' 역할을 담당하며 앱에서 다루는 데이터의 형식을 지정합니다.

class User {
  final String id;        // 사용자 고유 식별자
  final String name;      // 사용자 이름
  final String email;     // 사용자 이메일
  final String role;      // 권한 (예: admin, viewer)

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // 서버 통신(JSON) 결과를 Dart 객체로 변환하기 위한 팩토리 메서드입니다.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'viewer',
    );
  }

  // Dart 객체를 서버로 보낼 때 JSON으로 변환하는 메서드입니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
