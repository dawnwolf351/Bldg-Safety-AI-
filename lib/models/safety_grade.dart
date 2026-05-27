/// 시설물 안전등급 기준 모델 (백엔드 SafetyGrade 테이블과 동기화)
/// API: GET /api/safety-grades/
class SafetyGrade {
  final String grade;       // A, B, C, D, E
  final String label;       // 우수, 양호, 보통, 미흡, 불량
  final String state;       // 문제없음, 경미한 결함, ...
  final String description; // 상세 기준 요약

  SafetyGrade({
    required this.grade,
    required this.label,
    required this.state,
    required this.description,
  });

  factory SafetyGrade.fromJson(Map<String, dynamic> json) {
    return SafetyGrade(
      grade: json['grade'] ?? '',
      label: json['label'] ?? '',
      state: json['state'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
