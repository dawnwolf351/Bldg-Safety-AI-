import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceViewModel extends ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeviceViewModel() {
    // 초기 로딩 시 목데이터 셋업 (내일 실제 통신 전까지 UI 테스트용)
    _devices = [
      Device(
        id: 1, 
        deviceName: '본관 AI 카메라 01', 
        location: '본관 1층 로비', 
        macAddress: 'D2:80:54:74:5B:C7', 
        isOnline: true, 
        lastKnownIp: '192.168.1.10', 
        lastConnectedAt: '2026-03-26 10:15:37', 
        createdAt: '2026-01-01 10:00:00'
      ),
      Device(
        id: 2, 
        deviceName: '효민갤러리 AI 단말 02', 
        location: '효민갤러리 B1', 
        macAddress: 'A1:23:45:67:89:AB', 
        isOnline: true, 
        lastKnownIp: '192.168.1.11', 
        lastConnectedAt: '2026-03-26 10:18:22', 
        createdAt: '2026-02-15 11:30:00'
      ),
      Device(
        id: 3, 
        deviceName: '수덕전 AI 카메라 01', 
        location: '수덕전 1F', 
        macAddress: 'B2:34:56:78:9A:BC', 
        isOnline: false, 
        lastKnownIp: '192.168.1.12', 
        lastConnectedAt: '2026-03-25 15:40:11', 
        createdAt: '2026-01-10 09:20:00'
      ),
    ];
  }

  // 데이터 fetch (내일 실제 API 통신으로 변경될 부분)
  Future<void> fetchDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // API call simulation
      await Future.delayed(const Duration(seconds: 1));
      // 실제 API 데이터 파싱 및 갱신 로직 적용 예정
    } catch (e) {
      _errorMessage = '장치 목록을 불러오는 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 팀원들이 작성한(작성할) 기존 로직 보존용 껍데기 메서드들
  Future<void> deleteDevice(int id) async {
    _devices.removeWhere((device) => device.id == id);
    notifyListeners();
  }

  void mapsToAddDevice(BuildContext context) {
    // 기존 지도 / 장치 추가 화면으로 넘어가는 로직 보존
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('장치 추가 지도 화면(mapsToAddDevice)으로 이동합니다.'))
    );
  }
}
