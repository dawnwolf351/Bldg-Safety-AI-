import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// 실제 기기에서 알림, 진동, 경고음을 통합 관리하는 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  // ─── 초기화 (앱 시작 시 main.dart에서 1회 호출) ──────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Android 초기화 설정
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 초기화 설정
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    // iOS: 알림 권한 요청
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Android 13+: 알림 권한 요청
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ─── 긴급 푸시 알림 표시 ─────────────────────────────────────
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 500, 250, 500]);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'emergency_channel',
      '긴급 알림',
      channelDescription: '치명적 결함 감지 시 표시되는 긴급 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true, // iOS 14+ 포어그라운드 배너 표시 필수
      presentList: true,
      sound: 'default', // 기본 시스템 사운드 명시
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ─── 진동 실행 ───────────────────────────────────────────────
  Future<void> vibrate({bool emergency = false}) async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator() == true;
      if (!hasVibrator) return;

      if (emergency) {
        // 긴급 패턴
        if (Platform.isIOS) {
          // iOS는 CoreHaptics 커스텀 패턴 지원이 제한적이므로 기본 진동 여러번 호출
          await Vibration.vibrate();
          await Future.delayed(const Duration(milliseconds: 700));
          await Vibration.vibrate();
          await Future.delayed(const Duration(milliseconds: 700));
          await Vibration.vibrate();
        } else {
          // Android는 정밀한 패턴 제어 가능 [대기, 진동, 대기, 진동...]
          await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
        }
      } else {
        // 일반 경고: 1회 진동
        await Vibration.vibrate(duration: Platform.isIOS ? null : 400);
      }
    } catch (e) {
      debugPrint('진동 오류: $e');
    }
  }

  // ─── 경고음 재생 ─────────────────────────────────────────────
  Future<void> playAlertSound() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      // asset 없을 경우 묵음 처리 (시스템 알림음으로 대체)
      debugPrint('⚠️ alert.mp3 없음. 시스템 알림음으로 대체됩니다.');
    }
  }

  // ─── 야간 방해금지 시간 여부 확인 (22:00~07:00) ─────────────
  static bool isNightQuietHours() {
    final int hour = DateTime.now().hour;
    return hour >= 22 || hour < 7;
  }

  // ─── 통합 경고 실행 (알림 설정 상태에 따라 분기) ─────────────
  Future<void> triggerAlert({
    required bool pushEnabled,
    required bool soundVibrationEnabled,
    required bool doNotDisturbEnabled,
    required String title,
    required String body,
    bool isEmergency = false,
  }) async {
    // 야간 방해금지 체크
    if (doNotDisturbEnabled && isNightQuietHours()) {
      debugPrint('🌙 야간 방해금지 모드: 알림 억제됨');
      return;
    }

    // 긴급 푸시 알림
    if (pushEnabled) {
      await showEmergencyNotification(title: title, body: body);
    }

    // 소리 및 진동
    if (soundVibrationEnabled) {
      await Future.wait([
        vibrate(emergency: isEmergency),
        playAlertSound(),
      ]);
    }
  }
}
