import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/globals.dart';

// 인증 관련 로직과 상태를 관리하는 ViewModel입니다. (MVVM 패턴의 핵심)
// ChangeNotifier를 상속받아 상태가 변할 때마다 UI(View)에 알림을 보냅니다.
class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // [추가] 세션 관리를 위한 타이머 (서버 토큰 디코딩에 따라 동적 할당됨)
  Timer? _sessionTimer;
  Timer? _popupTimer;

  // 로그인 시도 (UI에서 선택한 역할 전달)
  Future<String?> login(String email, String password, {String? role}) async {
    _isLoading = true;
    notifyListeners(); // 로딩 상태 UI에 반영

    try {
      final user = await _apiService.login(email, password, roleOverride: role);
      _isLoading = false;

      if (user != null) {
        // 권한 교차 검증: 사용자가 누른 탭(권한)과 실제 가져온 계정의 권한이 다른지 심사
        // [수정] super_admin은 admin 탭으로 로그인 시도해도 허용함
        bool isRoleMatch = user.role == role || (user.role == 'super_admin' && role == 'admin');
        
        if (role != null && !isRoleMatch) {
          await _apiService.logout(); // 잘못 발급된 토큰 즉시 무효화
          notifyListeners();
          return '권한 불일치로 로그인 할 수 없습니다.\n[선택한 탭: $role, 서버응답 권한: ${user.role}]';
        }

        _currentUser = user; // 검증 통과 시 로그인 승인

        // 로그인 성공 시 세션 타이머(시한폭탄) 가동!
        startSessionTimer();

        notifyListeners();
        return null; // 성공 시 에러메시지(null) 반환
      } else {
        notifyListeners();
        return '아이디(이메일) 또는 비밀번호가 올바르지 않습니다.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return '로그인 중 오류가 발생했습니다.';
    }
  }

  // 로그아웃 처리
  Future<void> logout() async {
    cancelTimers(); // 강제 로그아웃 또는 수동 로그아웃 시 폭탄 해체
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // 회원가입 시도 및 유효성 검증
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    required String phone,
    String? adminCode,
    String? company,
  }) async {
    // 0. 추가 필드 검증 (전화번호 및 관리자 전용 필드)
    if (phone.isEmpty) {
      return '전화번호를 입력해주세요.';
    }

    // 전화번호 형식 철통 방어 (010-0000-0000 또는 01000000000 모두 허용)
    final phoneRegex = RegExp(r'^010-?\d{4}-?\d{4}$');
    if (!phoneRegex.hasMatch(phone)) {
      return '전화번호는 01000000000 형식으로 숫자만 입력하거나 하이픈(-)을 포함해주세요.';
    }
    if (role == 'admin') {
      if (adminCode == null || adminCode.trim().isEmpty) {
        return '현장 관리자 가입을 위해 올바른 인증 코드를 입력해주세요.';
      }

      // 관리자 인증 코드 4자리 숫자 강제
      if (!RegExp(r'^\d{4}$').hasMatch(adminCode.trim())) {
        return '현장 관리자 인증 코드는 숫자 4자리만 입력 가능합니다.';
      }

      if (company == null || company.trim().isEmpty) {
        return '소속 기관(회사명)을 입력해주세요.';
      }
    }

    // 1. 이메일 형식 검증 (정규식)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return '이메일은 "test@test.com" 형식으로 올바르게 입력해주세요.';
    }

    // 2. 비밀번호 일치 검증
    if (password != confirmPassword) {
      return '비밀번호와 비밀번호 확인이 일치하지 않습니다.';
    }

    // 3. 비밀번호 길이 검증
    if (password.length < 6) {
      return '비밀번호는 6자리 이상이어야 합니다.';
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 실제 API Service를 통해 회원가입(DB 연동) 데이터 전달
      final newUser = await _apiService.signUp({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        if (adminCode != null) 'adminCode': adminCode,
        if (company != null) 'company': company,
      });

      _isLoading = false;

      if (newUser != null) {
        // 성공 시 자동 로그인 효과
        _currentUser = newUser;
        startSessionTimer(); // 회원가입 후 자동 로그인 시에도 타이머 가동

        notifyListeners();
        return null; // 에러 메시지가 null이면 가입 성공을 의미 (UI에서 화면 전환)
      } else {
        notifyListeners();
        return '이미 가입된 정보가 있습니다.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      // DioException 등으로 서버 응답 자체가 에러(중복 등)로 떨어졌을 때도 이쪽으로 빠질 수 있음
      if (e.toString().contains('409') || e.toString().contains('400')) {
        return '이미 가입된 정보가 있습니다.';
      }
      return '서버와 통신하는 도중 문제가 발생했습니다.';
    }
  }

  // ===============================================
  // [세션 및 팝업 타이머 로직]
  // ===============================================

  void startSessionTimer() async {
    cancelTimers();

    // 서버 스펙: Access Token 5분(300초) 만료, Refresh Token 30분(1800초) 만료
    // Access Token 만료 1분 전(4분 = 240초)에 경고 팝업 발생!
    int showPopupAfterSeconds = 4 * 60;

    debugPrint('⏳ [세션 타이머] Access Token 5분 기준, 4분 뒤 경고 팝업 예약. (Refresh Token 30분)');

    _sessionTimer = Timer(Duration(seconds: showPopupAfterSeconds), () {
      _showSessionWarningPopup();
    });
  }

  void cancelTimers() {
    if (_sessionTimer != null) debugPrint('⏸️ [세션 타이머] 기존 타이머가 파괴되었습니다.');
    _sessionTimer?.cancel();
    _popupTimer?.cancel();
  }

  void _showSessionWarningPopup() {
    // globalNavKey를 통해 현재 화면이 뭔지 몰라도 전역으로 팝업을 강제 오버레이
    final context = globalNavKey.currentContext;
    debugPrint('👉 [세션 타이머] 화면 Context 상태: $context');

    if (context == null) {
      debugPrint(
          '🚨 [세션 타이머 에러] Context가 null입니다. 화면이 그려지기 전이거나 네비게이터 키가 끊겼습니다.');
      return;
    }

    // 팝업이 뜬 후 60초 동안 응답(입력)이 없으면 강제 로그아웃
    _popupTimer = Timer(const Duration(seconds: 60), () {
      Navigator.of(context, rootNavigator: true).pop(); // 강제로 팝업을 먼저 부숨
      _forceLogoutWithMessage('장시간 미입력으로 인해 보호조치(자동 로그아웃) 되었습니다.');
    });

    showDialog(
        context: context,
        barrierDismissible: false, // 팝업 바깥 빈 곳을 눌러도 안 꺼지도록 강제
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFFFF9F0A)),
                SizedBox(width: 8),
                Text('세션 만료 경고',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: const Text(
              '보안을 위해 1분 뒤 자동으로 로그아웃됩니다.\n계속해서 앱을 사용하시겠습니까?',
              style:
                  TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _popupTimer?.cancel();
                  Navigator.of(dialogContext).pop();
                  _forceLogoutWithMessage('사용자의 요청으로 즉시 로그아웃 처리되었습니다.');
                },
                child: Text('아니오(로그아웃)',
                    style: TextStyle(color: Colors.blueGrey[300])),
              ),
              ElevatedButton(
                onPressed: () async {
                  _popupTimer?.cancel();

                  // 실제 환경: 서버에 Refresh(토큰 연장)를 요청합니다.
                  final success = await _apiService.refreshToken();
                  if (!dialogContext.mounted) return; // async gap 방어
                  Navigator.of(dialogContext).pop();

                  if (success) {
                    startSessionTimer(); // 전달받은 새 토큰 정보로 타이머 자동 리셋!
                    if (!context.mounted) return; // async gap 방어
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('세션이 성공적으로 연장되었습니다.',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        backgroundColor: Color(0xFF06B6D4),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // 연장 실패 시 자동 로그아웃
                    _forceLogoutWithMessage('서버 연장 요청에 실패했습니다. 다시 로그인해주세요.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('예(시간 연장)',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
  }

  // 세션 만료 및 기타 이유로 강제로 튕겨낼 때 스낵바 메시지를 품고 나가는 함수
  void _forceLogoutWithMessage(String message) async {
    await logout(); // Consumer<AuthViewModel> 에 의해 로그인 뷰로 자동 회귀됨

    final context = globalNavKey.currentContext;
    if (context != null) {
      if (!context.mounted) return; // async gap 방어

      // 만약 세부 뷰(사진 상세 등)에 겹겹이 들어와 있더라도 최상위로 싹 다 팝 시켜서 초기화
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(message,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: const Color(0xFFFF3B30), // Red
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
