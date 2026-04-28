import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/device.dart';

// 서버와의 API 통신을 전담하는 Service 클래스 (REST API 연동 방식)
class ApiService {
  final Dio _dio = Dio();

  // JWT 토큰을 로컬에 안전하게 보관하는 스토리지
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 👉 백엔드 서버 호스팅 주소
  final String _baseUrl = 'http://121.144.41.106:5000'; // 친구분 서버 주소 연동 완료

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

  // 1. Dummy 로그인 (비활성화 상태 - 서버 연결용)
  /*
  Future<User?> login(String email, String password,
      {String? roleOverride}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final role = roleOverride ?? 'viewer';
    return User(
      id: 'dummy_user_1',
      name: role == 'admin' ? '현장 관리자(테스트)' : '일반 사용자(테스트)',
      email: email,
      role: role,
    );
  }
  */

  // 2. Dummy 회원가입 (비활성화 상태)
  /*
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
  */

  // =========== [진짜 서버 연동 코드 활성화] ===========

  // 1. HTTP API (REST) 실제 로그인 로직
  Future<User?> login(String email, String password,
      {String? roleOverride}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // 백엔드가 반환하는 토큰 필드명(access_token) 지원
        final String? token =
            response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          try {
            await _storage.write(key: 'jwt_token', value: token);
          } catch (e) {
            debugPrint('🚨 맥북 테스트 환경: 토큰 저장 스킵 (-34018 에러 무시)');
          }
        }
        final userData = response.data['user'] ?? {};

        // 플러터 UI 로직과 호환되게끔 백엔드의 role_id 숫자를 프론트엔드 문자열로 변환
        String parsedRole = 'viewer'; // 디폴트를 viewer로 잡고 시작 (사용자 탭 강제 덮어쓰기 방지)

        // user 객체 안이나, 최상단 응답 객체에 role_id가 있을 경우를 모두 고려
        final dynamic backendRoleId =
            userData['role_id'] ?? response.data['role_id'];
        final dynamic backendRoleStr =
            userData['role'] ?? response.data['role'];

        if (backendRoleId != null) {
          int rId = backendRoleId is int
              ? backendRoleId
              : int.tryParse(backendRoleId.toString()) ?? 3;
          if (rId == 1 || rId == 2) {
            parsedRole = 'admin'; // 최고관리자(1)와 관리자(2) 모두 앱에서는 관리자 탭 허용
          } else if (rId == 3) {
            parsedRole = 'viewer';
          }
        } else if (backendRoleStr != null) {
          String rawRole = backendRoleStr.toString().trim().toUpperCase();
          // 숫자(1,2)나 문자(ROLE_ADMIN) 모두 프론트엔드 관리자 탭 허용
          if (rawRole == '1' ||
              rawRole == '2' ||
              rawRole == 'ROLE_ADMIN' ||
              rawRole == 'ROLE_SUPERADMIN') {
            parsedRole = 'admin';
          }
          // 숫자(3)나 문자(ROLE_USER) 형태일 경우 일반 사용자로 허용
          else if (rawRole == '3' || rawRole == 'ROLE_USER') {
            parsedRole = 'viewer';
          } else {
            parsedRole = rawRole;
          }
        }

        return User(
          id: userData['id']?.toString() ??
              response.data['id']?.toString() ??
              'new_user',
          name: userData['name'] ?? response.data['name'] ?? 'Api User',
          email: email,
          role: parsedRole,
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
      // 프론트엔드의 문자열 'admin', 'viewer'를 백엔드 서버 스펙에 맞게 role_id 숫자로 변환합니다.
      // 최고관리자(1)는 제외, 관리자(admin)는 2, 일반사용자(viewer)는 3으로 매핑합니다.
      int roleId = (requestData['role'] == 'admin') ? 2 : 3;

      final response = await _dio.post('/api/auth/register', data: {
        'email': requestData['email'],
        'password': requestData['password'],
        'name': requestData['name'],
        'role_id': roleId, // 친구분 서버 스펙에 맞춘 필드 이름
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(requestData['email'], requestData['password'],
            roleOverride: requestData['role']);
      }
      return null;
    } catch (e) {
      debugPrint('🚨 HTTP SignUp Error: $e');
      return null;
    }
  }

  // 3. 로그아웃 (토큰 영구 파기)
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      // 맥OS 로컬 권한 충돌 무시
    }
  }

  // 4. 현재 저장된 생(Raw) 토큰값 꺼내기 (디코딩용)
  Future<String?> getSavedToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (e) {
      return null;
    }
  }

  // 5. 토큰 연장 (Refresh API HTTP 요청)
  Future<bool> refreshToken() async {
    try {
      final response = await _dio.post('/api/auth/refresh');
      // 친구 서버에서 200 성공을 뱉으며 새 토큰을 껴서 넘겨준다고 가정
      if (response.statusCode == 200) {
        final String? newToken =
            response.data['token'] ?? response.data['access_token'];
        if (newToken != null) {
          await _storage.write(key: 'jwt_token', value: newToken);
          return true; // 성공!
        }
      }
      return false;
    } catch (e) {
      debugPrint('🚨 HTTP Refresh Error (연장 실패): $e');
      return false;
    }
  }

  // 6. DB(jetson_devices)에 신규 장치 저장 프론트엔드 통신 로직
  Future<bool> addJetsonDevice(
      String macAddress, String deviceName, String location) async {
    try {
      // 명시적으로 토큰을 꺼내서 이번 요청 헤더에 강제 삽입 (친구분 서버 요구사항 반영)
      final token = await _storage.read(key: 'jwt_token');

      // 친구분이 요구하신 포맷(Content-Type, Authorization)을 100% 동일하게 헤더에 박아 넣습니다.
      final response = await _dio.post(
        '/api/devices',
        data: {
          'mac_address': macAddress,
          'device_name': deviceName,
          'location': location,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${token ?? ""}', // 토큰이 없더라도 형식은 맞춤
          },
        ),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 308;
    } catch (e) {
      debugPrint('🚨 HTTP addJetsonDevice Error (장치 추가 실패): $e');
      return false;
    }
  }

  // 7. DB(jetson_devices)에서 전체 장치 목록을 조회(GET)하는 통신 로직
  Future<List<Device>> getJetsonDevices() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      
      final response = await _dio.get(
        '/api/devices', // (백엔드 설계에 따라 /api/jetson_devices 일 수 있음. 친구분 협의 필요)
        options: Options(
          headers: {
            'Authorization': 'Bearer ${token ?? ""}',
          },
        ),
      );

      if (response.statusCode == 200) {
        // 서버가 "devices": [...] 형태로 주는지, 바로 [...] 배열로 주는지 모두 완벽 호환
        final List<dynamic> data = response.data['devices'] ?? response.data;
        
        return data.map((json) {
          return Device(
            id: json['id'] ?? 0,
            deviceName: json['device_name'] ?? '알 수 없는 단말',
            location: json['location'] ?? '위치 미지정',
            macAddress: json['mac_address'] ?? '알 수 없음',
            isOnline: json['is_online'] == true || json['is_online'] == 1,
            lastKnownIp: json['last_known_ip']?.toString() ?? 'IP 무할당',
            lastConnectedAt: json['last_connected_at']?.toString() ?? '기록 없음',
            createdAt: json['created_at']?.toString() ?? '방금 전',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 HTTP getJetsonDevices Error (목록 조회 실패): $e');
      return []; // 통신 실패나 404면 빈 배열 반환
    }
  }
}
