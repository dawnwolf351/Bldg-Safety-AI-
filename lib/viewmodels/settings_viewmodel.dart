import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  // Device & AI Configuration
  String _droneIp = '192.168.1.100'; // 기존 드론/장치 IP 설정용 (유지)
  String _dronePort = '5000';
  double _aiThreshold = 0.85; // 0.0 ~ 1.0

  // ─── 접속 기기(Client) IP 관리 ───
  String _clientIp = '불러오는 중...';
  String get clientIp => _clientIp;

  // Notification Settings
  bool _pushNotifications = true;
  bool _soundVibration = true;
  bool _doNotDisturb = false;

  // Getters
  String get droneIp => _droneIp;
  String get dronePort => _dronePort;
  double get aiThreshold => _aiThreshold;
  bool get pushNotifications => _pushNotifications;
  bool get soundVibration => _soundVibration;
  bool get doNotDisturb => _doNotDisturb;

  // 생성자에서 저장된 설정 불러오기
  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _soundVibration    = prefs.getBool('sound_vibration')    ?? true;
    _doNotDisturb      = prefs.getBool('do_not_disturb')     ?? false;
    notifyListeners();
  }

  // Setters
  void updateDroneConfig(String ip, String port) {
    _droneIp = ip;
    _dronePort = port;
    notifyListeners();
  }

  void updateAiThreshold(double value) {
    _aiThreshold = value;
    notifyListeners();
  }

  Future<void> togglePushNotifications(bool value) async {
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    notifyListeners();
  }

  Future<void> toggleSoundVibration(bool value) async {
    _soundVibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_vibration', value);
    notifyListeners();
  }

  Future<void> toggleDoNotDisturb(bool value) async {
    _doNotDisturb = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('do_not_disturb', value);
    notifyListeners();
  }

  Future<void> clearCache() async {
    // 임시 캐시 삭제 로직 대기 시간
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  Future<void> exportReport() async {
    // 임시 리포트 추출 로직 대기 시간
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  // 실제 기기의 네트워크 IP(공유기 할당 내부 IP) 자동 감지 로직
  Future<void> detectClientIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        // 첫 번째 유효한 IPv4 주소를 가져옵니다.
        _clientIp = interfaces.first.addresses.first.address;
      } else {
        _clientIp = 'IP를 찾을 수 없음';
      }
    } catch (e) {
      _clientIp = 'IP 감지 오류';
    }
    notifyListeners(); // UI 업데이트
  }
}
