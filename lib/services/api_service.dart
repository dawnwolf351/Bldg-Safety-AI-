import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart'; // 진짜 서버 켤 때 주석 푸시면 됩니다!
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

// 서버와의 API 통신을 전담하는 Service 클래스 (REST API 연동 방식)
class ApiService {
  final Dio _dio = Dio();

  // JWT 토큰을 로컬에 안전하게 보관하는 스토리지
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 👉 백엔드 개발자 PC의 주소 및 포트 (변경 시 이 부분만 갱신)
  final String _baseUrl = 'http://10.184.176.247:5001';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout =
        const Duration(seconds: 30); // 타임아웃 30초로 대폭 연장 (서버 딜레이 방어)
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // [인터셉터] 모든 요청에 토큰 자동 탑재
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    }, onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        //debugPrint('토큰 만료 혹은 비정상 접근 (401)');
        await logout();
      }
      return handler.next(e);
    }));
  }

  // ==========================================
  // [프론트엔드 UI 테스트용: Dummy 로직 활성화 중]
  // ==========================================

  // 1. Dummy 로그인 (서버 없이 항상 통과)
  Future<User?> login(String email, String password,
      {String? roleOverride}) async {
    // 0.5초 로딩 연출
    await Future.delayed(const Duration(milliseconds: 500));

    // UI에서 누른 역할(탭)을 그대로 수용하여 에러 없이 통과시킵니다.
    final role = roleOverride ?? 'viewer';

    return User(
      id: 'dummy_user_1',
      name: role == 'admin' ? '현장 관리자(테스트)' : '일반 사용자(테스트)',
      email: email,
      role: role,
    );
  }

  // 2. Dummy 회원가입 (서버 없이 항상 통과)
  Future<User?> signUp(Map<String, dynamic> requestData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final role = requestData['role'] ?? 'viewer';
    return User(
      id: 'dummy_user_1',
      name: requestData['name'] ?? '새로운 사용자',
      email: requestData['email'] ?? 'test@test.com',
      role: role,
    );
  }

  /* =========== [진짜 서버 연동 코드 보관함] ===========
  // 나중에 백엔드 서버가 켜지면, 위의 Dummy 로직 2개를 잠시 주석 처리하고 아래 이 코드를 풀어서 쓰세요!

  // 1. HTTP API (REST) 실제 로그인 로직
  Future<User?> login(String email, String password, {String? roleOverride}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final String? token = response.data['token'];
        if (token != null) {
          try {
            await _storage.write(key: 'jwt_token', value: token);
          } catch (e) {
            debugPrint('🚨 맥북 테스트 환경: 토큰 저장 스킵 (-34018 에러 무시)');
          }
        }
        final userData = response.data['user'] ?? {};
        return User(
          id: userData['id']?.toString() ?? 'new_user',
          name: userData['name'] ?? 'Api User',
          email: email,
          role: userData['role'] ?? roleOverride ?? 'viewer',
        );
      }
      return null;
    } catch (e) {
      debugPrint('🚨 HTTP Login DB Error: $e');
      return null;
    }
  }

  // 2. HTTP 실제 로컬 DB 회원가입 로직
  Future<User?> signUp(Map<String, dynamic> requestData) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': requestData['email'],
        'password': requestData['password'],
        'name': requestData['name'],
        'role': requestData['role'] ?? 'viewer',
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(requestData['email'], requestData['password'], roleOverride: requestData['role']);
      }
      return null;
    } catch (e) {
      debugPrint('🚨 HTTP SignUp Error: $e');
      return null;
    }
  }
  ====================================================== */

  // 3. 로그아웃 (토큰 영구 파기)
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      // 맥OS 로컬 테스트 시 권한 충돌 에러(-34018)를 무시하고 정상적으로 로그아웃되게끔 예외 처리
      //debugPrint('🚨 Logout Warning: $e');
    }
  }
}
