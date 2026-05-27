// 건물 표면의 결함 정보를 담는 Model 클래스입니다.
// 딥러닝 AI가 분석한 결함 기록을 앱에 표시하기 위해 사용됩니다.
// 백엔드 Swagger: GET /api/defects/ 응답 구조에 맞춤

class Defect {
  final int defectId;         // 결함 고유 ID (백엔드: defect_id)
  final int buildingId;       // 연결된 건물 ID (백엔드: building_id)
  final int deviceId;         // 탐지한 기기 ID (백엔드: device_id)
  final String defectType;    // 결함 종류 (예: 균열, 화재, 박리 등)
  final String? severity;     // 심각도 (경미 / 주의 / 심각)
  final String? imageUrl;     // AI 촬영 결함 사진 경로
  final String? comment;      // 상세 설명 / 작업자 코멘트
  final DateTime detectionTime; // 탐지 일시

  Defect({
    required this.defectId,
    required this.buildingId,
    required this.deviceId,
    required this.defectType,
    this.severity,
    this.imageUrl,
    this.comment,
    required this.detectionTime,
  });

  Defect copyWith({
    int? defectId,
    int? buildingId,
    int? deviceId,
    String? defectType,
    String? severity,
    String? imageUrl,
    String? comment,
    DateTime? detectionTime,
  }) {
    return Defect(
      defectId: defectId ?? this.defectId,
      buildingId: buildingId ?? this.buildingId,
      deviceId: deviceId ?? this.deviceId,
      defectType: defectType ?? this.defectType,
      severity: severity ?? this.severity,
      imageUrl: imageUrl ?? this.imageUrl,
      comment: comment ?? this.comment,
      detectionTime: detectionTime ?? this.detectionTime,
    );
  }

  /// 백엔드 JSON → Defect 객체 변환
  factory Defect.fromJson(Map<String, dynamic> json) {
    return Defect(
      defectId: json['defect_id'] ?? json['id'] ?? 0,
      buildingId: json['building_id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      defectType: json['defect_type']?.toString() ?? '알 수 없음',
      severity: json['severity']?.toString(),
      imageUrl: json['image_url']?.toString(),
      comment: json['comment']?.toString(),
      detectionTime: json['detection_time'] != null
          ? DateTime.tryParse(json['detection_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Defect 객체 → JSON 변환 (디버깅/전송용)
  Map<String, dynamic> toJson() {
    return {
      'defect_id': defectId,
      'building_id': buildingId,
      'device_id': deviceId,
      'defect_type': defectType,
      'severity': severity,
      'image_url': imageUrl,
      'comment': comment,
      'detection_time': detectionTime.toIso8601String(),
    };
  }

  /// 심각도를 앱 UI 상태 문자열로 변환 (CRITICAL / WARNING / SAFE)
  String get statusCode {
    switch (severity?.toUpperCase()) {
      case '심각':
      case 'E':
      case 'D':
        return 'CRITICAL';
      case '주의':
      case 'C':
        return 'WARNING';
      case '경미':
      case 'B':
      case 'A':
      default:
        return 'SAFE';
    }
  }

  /// 심각도를 한글 레이블로 변환
  String get statusLabel {
    switch (severity?.toUpperCase()) {
      case '심각':
      case 'E':
      case 'D':
        return '위험 감지';
      case '주의':
      case 'C':
        return '주의 필요';
      case '경미':
      case 'B':
      case 'A':
      default:
        return '안전(정상)';
    }
  }
}
