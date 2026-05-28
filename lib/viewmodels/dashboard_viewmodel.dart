import 'dart:async';
import 'package:flutter/material.dart';
import '../models/drone.dart';
import '../models/defect.dart';
import '../models/device_state.dart';
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

  // [추가] 특정 기기 상태 캐시 (device_id -> DeviceState)
  final Map<int, DeviceState> _deviceStates = {};
  Map<int, DeviceState> get deviceStates => _deviceStates;

  // [추가] 실시간 상태 갱신 타이머 (5초 주기)
  Timer? _stateRefreshTimer;

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
    _drones = [];
    _defects = [];

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

  // [추가] 전체 장비 상태 일괄 조회 및 캐시 업데이트
  Future<void> fetchAllDeviceStates() async {
    try {
      final states = await _apiService.getAllDeviceStates();
      for (final state in states) {
        _deviceStates[state.deviceId] = state;
      }
      if (states.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🚨 전체 기기 상태 일괄 조회 실패: $e');
    }
  }

  // [추가] 5초 주기 실시간 상태 갱신 시작
  void startAutoRefresh() {
    stopAutoRefresh(); // 기존 타이머 중복 방지
    // 즉시 한 번 조회
    fetchAllDeviceStates();
    // 5초마다 반복 조회
    _stateRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchAllDeviceStates(),
    );
    debugPrint('🔄 [대시보드] 실시간 상태 갱신 시작 (5초 주기)');
  }

  // [추가] 실시간 상태 갱신 중지
  void stopAutoRefresh() {
    _stateRefreshTimer?.cancel();
    _stateRefreshTimer = null;
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
    stopAutoRefresh();
    _webrtcService.disconnect();
    super.dispose();
  }
}
