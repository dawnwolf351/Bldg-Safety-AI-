import 'package:flutter/material.dart';
import '../models/drone.dart';
import '../models/defect.dart';
import '../models/device_state.dart';
import '../models/safety_grade.dart';
import '../services/webrtc_service.dart';
import '../services/api_service.dart';

// 대시보드 화면(기기 목록, 스트리밍, 결함 탐지 내역)의 상태를 관리하는 ViewModel
class DashboardViewModel extends ChangeNotifier {
  final WebRTCService _webrtcService = WebRTCService();
  final ApiService _apiService = ApiService();

  List<Drone> _drones = [];
  List<Defect> _defects = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _activeDroneId;

  // [추가] 시설물 안전등급 기준표
  List<SafetyGrade> _safetyGrades = [];
  List<SafetyGrade> get safetyGrades => _safetyGrades;

  // [추가] 특정 기기 상태 캐시 (device_id -> DeviceState)
  final Map<int, DeviceState> _deviceStates = {};
  Map<int, DeviceState> get deviceStates => _deviceStates;

  List<Drone> get drones => _drones;
  List<Defect> get defects => _defects;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get activeDroneId => _activeDroneId;

  // 서버에서 기기 목록과 이전 결함 데이터를 불러오는 함수
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    // 참고: 실제 DB/API 연동으로 교체 필요 (더미 데이터 제거 완료)
    // await Future.delayed(const Duration(seconds: 1));
    _drones = [];
    _defects = [];

    // [추가] 안전등급 기준표 비동기 로드
    try {
      _safetyGrades = await _apiService.getSafetyGrades();
    } catch (e) {
      debugPrint('🚨 안전등급 로드 실패: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // [추가] 특정 기기의 최신 상태 정보 조회
  Future<DeviceState?> fetchDeviceState(int deviceId) async {
    try {
      final state = await _apiService.getDeviceState(deviceId);
      if (state != null) {
        _deviceStates[deviceId] = state;
        notifyListeners();
      }
      return state;
    } catch (e) {
      debugPrint('🚨 기기 상태 조회 실패: $e');
      return null;
    }
  }

  // 특정 기기의 영상을 스트리밍하기 위해 WebRTC 서비스 호출
  Future<void> connectToDroneStream(String droneId) async {
    await _webrtcService.connectToStream(droneId);
    _activeDroneId = droneId;
    _isStreaming = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _webrtcService.disconnect();
    super.dispose();
  }
}
