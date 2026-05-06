import 'package:flutter/material.dart';
import '../models/drone.dart';
import '../models/defect.dart';
import '../services/webrtc_service.dart';

// 대시보드 화면(기기 목록, 스트리밍, 결함 탐지 내역)의 상태를 관리하는 ViewModel
class DashboardViewModel extends ChangeNotifier {
  final WebRTCService _webrtcService = WebRTCService();

  List<Drone> _drones = [];
  List<Defect> _defects = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _activeDroneId;

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

    _isLoading = false;
    notifyListeners();
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
