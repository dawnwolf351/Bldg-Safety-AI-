// 데이터의 구조를 정의하는 Model 클래스입니다.
// MVVM 패턴에서 'Model' 역할을 담당하며 앱에서 다루는 데이터의 형식을 지정합니다.

class User {
  final String id;        // 사용자 고유 식별자
  final String name;      // 사용자 이름
  final String email;     // 사용자 이메일
  final String role;      // 권한 (예: admin, viewer) - deprecated but kept for compatibility
  final String? roleName; // 직급 명 (ROLE_ADMIN, ROLE_USER 등)
  final int? level;       // 권한 레벨 (1, 2, 3)
  final String? createdAt; // 가입 일시

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleName,
    this.level,
    this.createdAt,
  });

  // 서버 통신(JSON) 결과를 Dart 객체로 변환하기 위한 팩토리 메서드입니다.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '', // int로 오든 String으로 오든 안전하게 파싱
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['role_name'] ?? 'viewer',
      roleName: json['role_name'],
      level: json['level'] is int ? json['level'] : int.tryParse(json['level']?.toString() ?? ''),
      createdAt: json['created_at'],
    );
  }

  // Dart 객체를 서버로 보낼 때 JSON으로 변환하는 메서드입니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'role_name': roleName,
      'level': level,
      'created_at': createdAt,
    };
  }
}
