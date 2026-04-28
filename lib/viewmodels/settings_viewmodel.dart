import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  // Device & AI Configuration
  String _droneIp = '192.168.1.100';
  String _dronePort = '5000';
  double _aiThreshold = 0.85; // 0.0 ~ 1.0

  // Notification Settings
  bool _pushNotifications = true;
  bool _soundVibration = true;

  // Getters
  String get droneIp => _droneIp;
  String get dronePort => _dronePort;
  double get aiThreshold => _aiThreshold;
  bool get pushNotifications => _pushNotifications;
  bool get soundVibration => _soundVibration;

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

  void togglePushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  void toggleSoundVibration(bool value) {
    _soundVibration = value;
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
}
