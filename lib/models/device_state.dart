/// Jetson 기기 상태 정보 모델 (백엔드 DeviceState 테이블과 동기화)
/// API: GET /api/devices/<device_id>/state
class DeviceState {
  final int id;
  final int deviceId;
  final String? recordedAt;

  // 연산 자원 (0~100%)
  final double cpuUsage;
  final double gpuUsage;
  final double gpuMemoryUsage;
  final double ramUsage;

  // 온도 (섭씨 ℃)
  final double temperatureSoc;
  final double temperatureCpu;
  final double temperatureGpu;

  // 추론 및 기기 상태
  final double? inferenceFps;
  final String? modelName;
  final String? cameraStatus;
  final String? depthSensorStatus;

  DeviceState({
    required this.id,
    required this.deviceId,
    this.recordedAt,
    required this.cpuUsage,
    required this.gpuUsage,
    required this.gpuMemoryUsage,
    required this.ramUsage,
    required this.temperatureSoc,
    required this.temperatureCpu,
    required this.temperatureGpu,
    this.inferenceFps,
    this.modelName,
    this.cameraStatus,
    this.depthSensorStatus,
  });

  factory DeviceState.fromJson(Map<String, dynamic> json) {
    return DeviceState(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      recordedAt: json['recorded_at'],
      cpuUsage: (json['cpu_usage'] ?? 0).toDouble(),
      gpuUsage: (json['gpu_usage'] ?? 0).toDouble(),
      gpuMemoryUsage: (json['gpu_memory_usage'] ?? 0).toDouble(),
      ramUsage: (json['ram_usage'] ?? 0).toDouble(),
      temperatureSoc: (json['temperature_soc'] ?? 0).toDouble(),
      temperatureCpu: (json['temperature_cpu'] ?? 0).toDouble(),
      temperatureGpu: (json['temperature_gpu'] ?? 0).toDouble(),
      inferenceFps: json['inference_fps'] != null ? (json['inference_fps']).toDouble() : null,
      modelName: json['model_name'],
      cameraStatus: json['camera_status'],
      depthSensorStatus: json['depth_sensor_status'],
    );
  }

  /// 가장 높은 온도 반환 (과열 판단용)
  double get maxTemperature {
    double max = temperatureSoc;
    if (temperatureCpu > max) max = temperatureCpu;
    if (temperatureGpu > max) max = temperatureGpu;
    return max;
  }

  /// 과열 상태 여부 (80도 이상)
  bool get isOverheated => maxTemperature >= 80.0;
}
