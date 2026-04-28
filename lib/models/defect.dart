// 건물 표면의 결함 정보를 담는 Model 클래스입니다.
// 딥러닝 AI가 분석한 결함 기록을 앱에 표시하기 위해 사용됩니다.

class Defect {
  final String id;          // 결함 식별자
  final String type;        // 결함 종류 (예: crack-균열, spalling-박리, corrosion-부식 등)
  final double severity;    // 심각도 (0.0 ~ 1.0 또는 0% ~ 100%)
  final DateTime timestamp; // 발견된 일시
  final String imageUrl;    // 결함이 찍힌 프레임/사진 이미지 URL

  Defect({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.imageUrl,
  });

  factory Defect.fromJson(Map<String, dynamic> json) {
    return Defect(
      id: json['id'] ?? '',
      type: json['type'] ?? 'unknown',
      severity: (json['severity'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
