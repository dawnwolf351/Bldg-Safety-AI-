// 기기(모듈) 상태를 정의하는 Model 클래스입니다.
// 실시간 건축물 진단에서 카메라나 단말의 연결 상태 및 배터리 등을 표시할 때 활용합니다.

class Drone {
  final String id;            // 기기 고유 번호
  final String name;          // 기기 명칭
  final String status;        // 상태 (예: offline, flying, returning, idle)
  final int batteryLevel;     // 배터리 잔량 (0~100)

  Drone({
    required this.id,
    required this.name,
    required this.status,
    required this.batteryLevel,
  });

  factory Drone.fromJson(Map<String, dynamic> json) {
    return Drone(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Drone',
      status: json['status'] ?? 'offline',
      batteryLevel: json['batteryLevel'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'batteryLevel': batteryLevel,
    };
  }
}
