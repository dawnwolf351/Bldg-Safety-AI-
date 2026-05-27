import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class EmergencyAlert {
  static bool _isAlertShowing = false;
  static AudioPlayer? _player;

  /// 긴급 위험 감지(E등급) 팝업을 띄우고 사이렌 소리를 냅니다.
  /// 전역적으로 호출 가능하도록 설계되었습니다.
  static Future<void> show(BuildContext context) async {
    // 중복 실행 방지
    if (_isAlertShowing) return;
    _isAlertShowing = true;

    _player = AudioPlayer();
    
    // 삐용삐용 사이렌 소리 재생 (반복 설정)
    await _player?.setReleaseMode(ReleaseMode.loop);
    await _player?.play(AssetSource('siren.wav'));

    if (!context.mounted) {
      _isAlertShowing = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // 화이트 테마 깔끔하게
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30)),
            SizedBox(width: 8),
            Text('긴급 위험 감지', style: TextStyle(color: Color(0xFF1A1D21), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '현장 시스템에 심각한 이상이 감지되었습니다.\n모든 관리자에게 알림이 전송되며, 즉각적인 현장 대피 및 보수 지시가 필요합니다.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.5, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _player?.stop();
              await _player?.dispose();
              _player = null;
              _isAlertShowing = false;

              if (!ctx.mounted) return;
              Navigator.pop(ctx); // 팝업 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('알림 종료 및 확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((_) {
      // 만약 외부 요인으로 다이얼로그가 닫히면 상태 리셋
      _player?.stop();
      _player?.dispose();
      _player = null;
      _isAlertShowing = false;
    });
  }
}
