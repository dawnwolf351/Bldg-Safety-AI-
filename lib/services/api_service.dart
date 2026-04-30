import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/device.dart';

// 서버와의 API 통신을 전담하는 Service 클래스 (REST API 연동 방식)
// 백엔드 Swagger API 스펙 기준으로 완전 동기화됨
class ApiService {
  final Dio _dio = Dio();

  // JWT 토큰을 로컬에 안전하게 보관하는 스토리지
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // [메모리 캐시] 맥북 시뮬레이터 등 저장소 오류 발생 시 백업용
  static String? _tokenCache;        // access_token 캐시
  static String? _refreshTokenCache; // refresh_token 캐시 (별도 관리)

  // [토큰 갱신 중복 방지] 여러 요청이 동시에 401을 받을 때 refresh를 한 번만 수행
  bool _isRefreshing = false;

  // 👉 백엔드 서버 호스팅 주소
  final String _baseUrl = 'http://121.144.41.106:5000';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // =====================================================
    // [인터셉터] 모든 요청에 access_token 자동 탑재 + 401 시 자동 갱신
    // =====================================================
    _dio.interceptors.add(InterceptorsWrapper(
      // --- onRequest: 모든 요청에 access_token 자동 삽입 ---
      onRequest: (options, handler) async {
        String? token = _tokenCache;
        token ??= await _storage.read(key: 'jwt_token').catchError((e) => null);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      // --- onError: 401 수신 시 refresh_token으로 자동 갱신 후 재시도 ---
      onError: (DioException e, handler) async {
        final requestOptions = e.requestOptions;

        // refresh 요청 자체가 실패하면 무한루프 방지
        if (requestOptions.path.contains('/api/auth/refresh')) {
          debugPrint('🚨 [인터셉터] Refresh 요청 자체 실패 → 로그인 필요');
          await logout();
          return handler.next(e);
        }

        // 401 에러 → access_token 만료 → refresh_token으로 새 access_token 발급
        if (e.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          debugPrint('🔄 [인터셉터] 401 감지! refresh_token으로 자동 갱신 시도...');

          try {
            String? refreshTk = _refreshTokenCache;
            refreshTk ??= await _storage.read(key: 'jwt_refresh_token').catchError((e) => null);

            if (refreshTk == null) {
              debugPrint('🚨 [인터셉터] Refresh Token 없음 → 갱신 불가');
              _isRefreshing = false;
              return handler.next(e);
            }

            // ★ 백엔드 Swagger 스펙: POST /api/auth/refresh
            //   요청 Body(JSON): { "refresh_token": "...", "extend": false }
            //   헤더에 넣는 것이 아님!
            final refreshResponse = await Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )).post(
              '/api/auth/refresh',
              data: {
                'refresh_token': refreshTk,
                'extend': false,
              },
              options: Options(headers: {
                'Content-Type': 'application/json',
              }),
            );

            if (refreshResponse.statusCode == 200) {
              final String? newAccessToken = refreshResponse.data['access_token'];

              if (newAccessToken != null) {
                // 새 access_token 저장
                _tokenCache = newAccessToken;
                try {
                  await _storage.write(key: 'jwt_token', value: newAccessToken);
                } catch (_) {}

                // 새 refresh_token이 응답에 있으면 갱신 (extend=true 시)
                final String? newRefreshToken = refreshResponse.data['refresh_token'];
                if (newRefreshToken != null) {
                  _refreshTokenCache = newRefreshToken;
                  try {
                    await _storage.write(key: 'jwt_refresh_token', value: newRefreshToken);
                  } catch (_) {}
                }

                debugPrint('✅ [인터셉터] 토큰 갱신 성공! 원래 요청 재시도...');

                // 원래 요청을 새 토큰으로 재시도
                requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final retryResponse = await _dio.fetch(requestOptions);
                _isRefreshing = false;
                return handler.resolve(retryResponse);
              }
            }

            debugPrint('🚨 [인터셉터] 토큰 갱신 실패 (서버 응답: ${refreshResponse.statusCode})');
            _isRefreshing = false;
            return handler.next(e);

          } catch (refreshError) {
            debugPrint('🚨 [인터셉터] 토큰 갱신 중 예외: $refreshError');
            _isRefreshing = false;
            return handler.next(e);
          }
        }

        return handler.next(e);
      },
    ));
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
  // 백엔드 응답 구조:
  // {
  //   "message": "홍길동님 환영합니다!",
  //   "access_token": "...",
  //   "refresh_token": "...",
  //   "role": "ROLE_ADMIN",
  //   "level": 2,
  //   "user": { "id": 1, "email": "...", "name": "...", "role_name": "ROLE_ADMIN", "level": 2 }
  // }
  Future<User?> login(String email, String password,
      {String? roleOverride}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // access_token 저장
        final String? token = response.data['access_token'];
        if (token != null) {
          _tokenCache = token;
          try {
            await _storage.write(key: 'jwt_token', value: token);
          } catch (e) {
            debugPrint('🚨 맥북 테스트 환경: 토큰 저장소(Storage) 쓰기 실패 - 메모리 캐시 사용');
          }
        }

        // refresh_token 저장
        final String? refreshToken = response.data['refresh_token'];
        if (refreshToken != null) {
          _refreshTokenCache = refreshToken;
          try {
            await _storage.write(key: 'jwt_refresh_token', value: refreshToken);
          } catch (_) {}
          debugPrint('✅ [로그인] Access + Refresh Token 모두 저장 완료');
        }

        final userData = response.data['user'] ?? {};

        // ★ 백엔드 Swagger 기준: level 필드로 권한 판별 (1=최고관리자, 2=관리자, 3=일반)
        // 최상위 응답의 level 또는 user 객체 내 level 둘 다 지원
        String parsedRole = 'viewer';
        final dynamic level = response.data['level'] ?? userData['level'];
        final dynamic roleName = response.data['role'] ?? userData['role_name'];

        if (level != null) {
          int lvl = level is int ? level : int.tryParse(level.toString()) ?? 3;
          if (lvl == 1) {
            parsedRole = 'super_admin';
          } else if (lvl == 2) {
            parsedRole = 'admin';
          } else {
            parsedRole = 'viewer';
          }
        } else if (roleName != null) {
          String rawRole = roleName.toString().trim().toUpperCase();
          if (rawRole == 'ROLE_SUPER_ADMIN' || rawRole == 'ROLE_SUPERADMIN') {
            parsedRole = 'super_admin';
          } else if (rawRole == 'ROLE_ADMIN') {
            parsedRole = 'admin';
          } else {
            parsedRole = 'viewer';
          }
        }

        return User(
          id: userData['id']?.toString() ?? response.data['id']?.toString() ?? 'new_user',
          name: parsedRole == 'super_admin' 
              ? '최고관리자' 
              : (userData['name'] ?? response.data['name'] ?? 'Api User'),
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
      int roleId = (requestData['role'] == 'admin') ? 2 : 3;

      final response = await _dio.post('/api/auth/register', data: {
        'email': requestData['email'],
        'password': requestData['password'],
        'name': requestData['name'],
        'role_id': roleId,
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
    _tokenCache = null;
    _refreshTokenCache = null;
    try {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'jwt_refresh_token');
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

  // 5. 토큰 연장 (세션 경고 팝업에서 호출) - extend=true로 refresh_token도 리셋
  // 백엔드 Swagger: POST /api/auth/refresh
  //   Body: { "refresh_token": "...", "extend": true }
  //   Response: { "access_token": "...", "refresh_token": "..." (extend 시) }
  Future<bool> refreshToken() async {
    try {
      String? refreshTk = _refreshTokenCache;
      refreshTk ??= await _storage.read(key: 'jwt_refresh_token').catchError((e) => null);

      if (refreshTk == null) {
        debugPrint('🚨 [토큰 연장] Refresh Token 없음 → 연장 불가');
        return false;
      }

      // ★ 세션 연장 버튼이므로 extend=true (refresh_token 30분도 리셋)
      final response = await Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      )).post(
        '/api/auth/refresh',
        data: {
          'refresh_token': refreshTk,
          'extend': true,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final String? newAccessToken = response.data['access_token'];
        if (newAccessToken != null) {
          _tokenCache = newAccessToken;
          try {
            await _storage.write(key: 'jwt_token', value: newAccessToken);
          } catch (_) {}

          // extend=true 응답 시 새 refresh_token도 저장
          final String? newRefreshToken = response.data['refresh_token'];
          if (newRefreshToken != null) {
            _refreshTokenCache = newRefreshToken;
            try {
              await _storage.write(key: 'jwt_refresh_token', value: newRefreshToken);
            } catch (_) {}
          }

          debugPrint('✅ [토큰 연장] Access + Refresh 모두 갱신 성공!');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('🚨 HTTP Refresh Error (연장 실패): $e');
      return false;
    }
  }

  // =====================================================
  // [장치(Device) API] - 인터셉터가 토큰을 자동 탑재하므로
  //                     개별 메서드에서 수동 헤더 세팅 제거!
  // =====================================================

  // 6. 장치 등록 (POST /api/devices/)
  Future<bool> addJetsonDevice(
      String macAddress, String deviceName, String location) async {
    try {
      final response = await _dio.post(
        '/api/devices/',
        data: {
          'mac_address': macAddress,
          'device_name': deviceName,
          'location': location,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 HTTP addJetsonDevice Error (장치 추가 실패): $e');
      return false;
    }
  }

  // 7. 장치 수정 (PUT /api/devices/<id>)
  // 백엔드 Swagger: device_name, location만 수정 가능 (mac_address 수정 불가)
  Future<bool> updateJetsonDevice(int id, String macAddress, String deviceName, String location) async {
    debugPrint('📝 [수정 시작] 대상 ID: $id, 이름: $deviceName');
    try {
      final response = await _dio.put(
        '/api/devices/$id',
        data: {
          'device_name': deviceName,
          'location': location,
        },
      );
      debugPrint('✅ [수정 결과] 상태코드: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('🚨 [수정 에러] 상세 내용: $e');
      return false;
    }
  }

  // 8. 장치 삭제 (DELETE /api/devices/<id>) - 관리자 레벨 2 이상
  Future<bool> deleteJetsonDevice(int id) async {
    debugPrint('🗑️ [삭제 시작] 대상 ID: $id');
    try {
      final response = await _dio.delete('/api/devices/$id');
      debugPrint('✅ [삭제 결과] 상태코드: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('🚨 [삭제 에러] 상세 내용: $e');
      return false;
    }
  }

  // 9. 전체 장치 목록 조회 (GET /api/devices/)
  // 백엔드 응답: List<DeviceResponse> (배열 형태)
  Future<List<Device>> getJetsonDevices() async {
    debugPrint('🔍 [STEP 0] getJetsonDevices 진입!');
    try {
      final response = await _dio.get('/api/devices/');
      debugPrint('🔍 [응답] 상태코드: ${response.statusCode}, 데이터 타입: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        dynamic parsed = response.data;
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }

        List<dynamic> data = [];
        if (parsed is List) {
          data = parsed;
        } else if (parsed is Map && parsed['devices'] != null) {
          data = parsed['devices'];
        } else if (parsed is Map && parsed['data'] != null) {
          data = parsed['data'];
        } else if (parsed is Map) {
          for (var v in parsed.values) {
            if (v is List) { data = v; break; }
          }
        }
        
        debugPrint('🔍 [GET 장치목록] 파싱된 장치 수: ${data.length}개');
        
        return data.map((json) {
          return Device(
            // 백엔드 Swagger: device_id 필드명 사용
            id: (json['device_id'] ?? json['id'] ?? 0) is int 
                ? json['device_id'] ?? json['id'] ?? 0
                : int.tryParse(json['device_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
            deviceName: json['device_name']?.toString() ?? '알 수 없는 단말',
            location: json['location']?.toString() ?? '위치 미지정',
            macAddress: json['mac_address']?.toString() ?? '권한 없음', // 레벨3은 숨김 처리됨
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
      throw Exception('서버 데이터 파싱 오류 또는 통신 실패: $e');
    }
  }
}
