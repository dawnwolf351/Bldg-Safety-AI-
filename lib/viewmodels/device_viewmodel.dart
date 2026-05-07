import 'package:flutter/material.dart';
import 'dart:async';
import '../models/device.dart';
import '../services/api_service.dart';

class DeviceViewModel extends ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer; // [추가] 실시간 동기화를 위한 타이머

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeviceViewModel() {
    _devices = [];
    startPolling(); // 생성 시 폴링 시작
  }

  // [추가] 10초마다 서버에서 데이터를 새로 긁어오는 시한폭탄
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // 화면이 보고 있을 때만 조용히 새로고침 (로딩바 없이)
      _silentFetch();
    });
  }

  Future<void> _silentFetch() async {
    try {
      final latest = await ApiService().getJetsonDevices();
      // ★ 데이터가 실제로 변했을 때만 UI 갱신 (deep compare)
      // 길이만 비교하면 isOnline 변경 등을 놓치고,
      // 매번 notifyListeners()를 호출하면 VideoStreamWidget이 재생성되어 영상이 끊김
      if (_isDeviceListChanged(latest)) {
        _devices = latest;
        notifyListeners();
      }
    } catch (e) {
      // 폴링 중 에러는 조용히 무시
    }
  }

  // 장치 목록이 실제로 변경되었는지 비교 (id, 이름, 온라인 상태 등)
  bool _isDeviceListChanged(List<Device> latest) {
    if (latest.length != _devices.length) return true;
    for (int i = 0; i < latest.length; i++) {
      if (latest[i].id != _devices[i].id ||
          latest[i].deviceName != _devices[i].deviceName ||
          latest[i].isOnline != _devices[i].isOnline ||
          latest[i].lastKnownIp != _devices[i].lastKnownIp) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // 메모리 누수 방지
    super.dispose();
  }

  // 데이터 fetch (실제 API DB 데이터 긁어오기)
  Future<void> fetchDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 플러터 앱이 켜질 때 백엔드에 SELECT 요청을 날려서 _devices 배열을 가득 채웁니다!
      _devices = await ApiService().getJetsonDevices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // [추가] 에러 메시지 초기화 (스낵바 등으로 보여준 뒤 호출)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // [추가됨] DB에서 장치 삭제 통신 후 성공 시 화면 새로고침
  Future<bool> deleteDevice(int id) async {
    final success = await ApiService().deleteJetsonDevice(id);
    if (success) {
      // 서버에서 성공적으로 삭제되었으면 로컬 목록 다시 불러오기
      await fetchDevices();
      return true;
    } else {
      _errorMessage = '서버에서 장치를 삭제하는데 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  void mapsToAddDevice(BuildContext context) {
    // 기존 지도 / 장치 추가 화면으로 넘어가는 로직 보존
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장치 추가 지도 화면(mapsToAddDevice)으로 이동합니다.')));
  }
}
