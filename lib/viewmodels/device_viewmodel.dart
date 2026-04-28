import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/api_service.dart';

class DeviceViewModel extends ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeviceViewModel() {
    // 사용자의 요청으로 로컬 목 데이터(더미 데이터)를 모두 지웁니다.
    _devices = [];
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
      _errorMessage = '서버에서 장치 목록을 불러오는 중 오류가 발생했습니다.';
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

  // [추가됨] DB 등록 성공 시, 화면을 즉시 새로고침하기 위해 로컬 배열에 데이터 강제 주입
  void appendNewDevice(String mac, String name, String location) {
    final newDevice = Device(
      id: _devices.isNotEmpty ? _devices.last.id + 1 : 1, // 간단한 더미 ID 부여
      deviceName: name,
      location: location,
      macAddress: mac,
      isOnline: false, // 새로 설치했으므로 오프라인/대기상태로 판정
      lastKnownIp: 'IP 무할당',
      lastConnectedAt: '연결 기록 없음',
      createdAt: '방금 전 추가됨',
    );
    _devices.insert(0, newDevice); // 리스트 맨 위에 노출
    notifyListeners(); // 이 함수가 호출되어야 화면 뷰가 '아, 목록이 바뀌었구나' 하고 리렌더링 됨!
  }

  void mapsToAddDevice(BuildContext context) {
    // 기존 지도 / 장치 추가 화면으로 넘어가는 로직 보존
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('장치 추가 지도 화면(mapsToAddDevice)으로 이동합니다.'))
    );
  }
}
