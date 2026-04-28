import 'dart:async';
import 'package:flutter/foundation.dart';

// 현장 카메라 비디오 스트리밍을 처리하기 위한 WebRTC 서비스 스켈레톤입니다.
// (차후 영상 분석 모듈과 연결 시 데이터 전송 통로로 사용 가능)
class WebRTCService {
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;

  // 스트리밍 서버에 연결합니다.
  Future<void> connectToStream(String droneId) async {
    // 실제 WebRTC (flutter_webrtc 패키지 등) 연결 로직 구현부
    debugPrint('Connecting to drone $droneId video stream...');
    await Future.delayed(const Duration(seconds: 2));
    _isConnected = true;
    debugPrint('Connected successfully.');
  }

  // 스트리밍 서버 연결을 해제합니다.
  void disconnect() {
    _isConnected = false;
    debugPrint('WebRTC disconnected.');
  }
}
