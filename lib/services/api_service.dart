import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/device.dart';
import '../models/building.dart';
import '../models/defect.dart';
import '../models/device_state.dart';

// 서버와의 API 통신을 전담하는 Service 클래스 (REST API 연동 방식)
// 백엔드 Swagger API 스펙 기준으로 완전 동기화됨
class ApiService {
  final Dio _dio = Dio();

  // JWT 토큰을 로컬에 안전하게 보관하는 스토리지
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // [메모리 캐시] 맥북 시뮬레이터 등 저장소 오류 발생 시 백업용
  static String? _tokenCache; // access_token 캐시
  static String? _refreshTokenCache; // refresh_token 캐시 (별도 관리)

  // [토큰 갱신 중복 방지] 여러 요청이 동시에 401을 받을 때 refresh를 한 번만 수행
  bool _isRefreshing = false;

  // 👉 백엔드 서버 호스팅 주소 (외부 접근용 static 상수)
  static const String serverBaseUrl = 'http://121.144.41.106:1310';
  final String _baseUrl = serverBaseUrl;

  /// 서버에서 반환된 상대 경로 image_url을 완전한 URL로 변환
  /// 예) /uploads/defects/abc.jpg → http://121.144.41.106:1310/uploads/defects/abc.jpg
  static String? buildImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;
    if (relativeUrl.startsWith('http')) return relativeUrl; // 이미 절대 URL이면 그대로
    return '$serverBaseUrl$relativeUrl';
  }

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
            refreshTk ??= await _storage
                .read(key: 'jwt_refresh_token')
                .catchError((e) => null);

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
              final String? newAccessToken =
                  refreshResponse.data['access_token'];

              if (newAccessToken != null) {
                // 새 access_token 저장
                _tokenCache = newAccessToken;
                try {
                  await _storage.write(key: 'jwt_token', value: newAccessToken);
                } catch (_) {}

                // 새 refresh_token이 응답에 있으면 갱신 (extend=true 시)
                final String? newRefreshToken =
                    refreshResponse.data['refresh_token'];
                if (newRefreshToken != null) {
                  _refreshTokenCache = newRefreshToken;
                  try {
                    await _storage.write(
                        key: 'jwt_refresh_token', value: newRefreshToken);
                  } catch (_) {}
                }

                debugPrint('✅ [인터셉터] 토큰 갱신 성공! 원래 요청 재시도...');

                // 원래 요청을 새 토큰으로 재시도
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final retryResponse = await _dio.fetch(requestOptions);
                _isRefreshing = false;
                return handler.resolve(retryResponse);
              }
            }

            debugPrint(
                '🚨 [인터셉터] 토큰 갱신 실패 (서버 응답: ${refreshResponse.statusCode})');
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
  // [인증 API] 현재 프론트 단독 모드 (서버 연동 준비 중)
  // ==========================================

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
  // 1. 로그인
  Future<User?> login(String email, String password,
      {String? roleOverride}) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 3)); // 3초만 시도

      if (response.statusCode == 200) {
        final data = response.data;
        _tokenCache = data['access_token'];
        _refreshTokenCache = data['refresh_token'];

        await _storage.write(key: 'jwt_token', value: _tokenCache);
        if (_refreshTokenCache != null) {
          await _storage.write(
              key: 'jwt_refresh_token', value: _refreshTokenCache);
        }

        final userInfo = data['user'];
        String parsedRole = 'viewer';

        // level 정보를 루트와 user 객체 모두에서 안전하게 추출 (문자열인 경우도 고려)
        dynamic levelData =
            data['level'] ?? (userInfo != null ? userInfo['level'] : null);
        int level = 3;
        if (levelData != null) {
          level = int.tryParse(levelData.toString()) ?? 3;
        }

        if (level == 1) {
          parsedRole = 'super_admin';
        } else if (level == 2) {
          parsedRole = 'admin';
        }

        return User(
          id: userInfo['id'].toString(),
          name: userInfo['name'],
          email: userInfo['email'],
          role: parsedRole,
        );
      }
    } catch (e) {
      debugPrint('🚨 HTTP Login Error: $e');
    }
    return null;
  }

  // 2. 회원가입
  Future<User?> signUp(Map<String, dynamic> requestData) async {
    try {
      int roleId = 3;
      if (requestData['role'] == 'admin') roleId = 2;

      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': requestData['email'],
          'password': requestData['password'],
          'name': requestData['name'],
          'role_id': roleId,
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 201) {
        return login(requestData['email'], requestData['password']);
      }
    } catch (e) {
      debugPrint('🚨 HTTP SignUp Error: $e');
      rethrow;
    }
    return null;
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
      refreshTk ??=
          await _storage.read(key: 'jwt_refresh_token').catchError((e) => null);

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
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _tokenCache = newAccessToken; // 메모리 캐시 즉시 업데이트
          debugPrint(
              '✅ [토큰 연장] 새 Access Token 캐시 업데이트 성공: ${newAccessToken.substring(0, 10)}...');
          try {
            await _storage.write(key: 'jwt_token', value: newAccessToken);
          } catch (_) {}

          // extend=true 응답 시 새 refresh_token도 저장
          final String? newRefreshToken = response.data['refresh_token'];
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            _refreshTokenCache = newRefreshToken;
            try {
              await _storage.write(
                  key: 'jwt_refresh_token', value: newRefreshToken);
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
  // 백엔드 Swagger: device_name, location만 수정 가능 (mac_address 수정 불가) -> 수정 가능하게 페이로드 추가
  Future<bool> updateJetsonDevice(
      int id, String macAddress, String deviceName, String location) async {
    debugPrint('📝 [수정 시작] 대상 ID: $id, 이름: $deviceName');
    try {
      final response = await _dio.put(
        '/api/devices/$id',
        data: {
          'mac_address': macAddress,
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
      debugPrint(
          '🔍 [응답] 상태코드: ${response.statusCode}, 데이터 타입: ${response.data.runtimeType}');

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
            if (v is List) {
              data = v;
              break;
            }
          }
        }

        debugPrint('🔍 [GET 장치목록] 파싱된 장치 수: ${data.length}개');

        return data.map((json) {
          return Device(
            // 백엔드 Swagger: device_id 필드명 사용
            id: (json['device_id'] ?? json['id'] ?? 0) is int
                ? json['device_id'] ?? json['id'] ?? 0
                : int.tryParse(json['device_id']?.toString() ??
                        json['id']?.toString() ??
                        '0') ??
                    0,
            deviceName: json['device_name']?.toString() ?? '알 수 없는 단말',
            location: json['location']?.toString() ?? '위치 미지정',
            macAddress:
                json['mac_address']?.toString() ?? '권한 없음', // 레벨3은 숨김 처리됨
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

  // ==========================================
  // [건물(Building) API]
  // ==========================================

  // 10. 전체 건물 목록 조회 (GET /api/buildings/)
  Future<List<Building>> getBuildings() async {
    try {
      final response = await _dio.get('/api/buildings/');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Building.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 HTTP getBuildings Error: $e');
      return [];
    }
  }

  // 11. 건물 추가 (POST /api/buildings/)
  Future<bool> addBuilding(
      String name, String location, String? completionDate) async {
    try {
      final response = await _dio.post(
        '/api/buildings/',
        data: {
          'building_name': name,
          'location': location,
          'completion_date': completionDate,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 HTTP addBuilding Error: $e');
      return false;
    }
  }

  // 12. 건물 수정 (PUT /api/buildings/<id>)
  Future<bool> updateBuilding(
      int id, String name, String location, String? completionDate) async {
    try {
      final response = await _dio.put(
        '/api/buildings/$id',
        data: {
          'building_name': name,
          'location': location,
          'completion_date': completionDate,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP updateBuilding Error: $e');
      return false;
    }
  }

  // 13. 건물 삭제 (DELETE /api/buildings/<id>)
  Future<bool> deleteBuilding(int id) async {
    try {
      final response = await _dio.delete('/api/buildings/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP deleteBuilding Error: $e');
      return false;
    }
  }

  // ==========================================
  // [결함(Defect) API] - 진단 이력 조회/상세/삭제
  // 백엔드 Swagger: /api/defects/
  // ==========================================

  // 14. 전체 결함 이력 목록 조회 (GET /api/defects/)
  Future<List<Defect>> getDefects() async {
    debugPrint('🔍 [결함 목록] getDefects 호출');
    try {
      final response = await _dio.get('/api/defects/');
      debugPrint('🔍 [결함 목록] 상태코드: ${response.statusCode}, 데이터 타입: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        dynamic parsed = response.data;
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }

        List<dynamic> data = [];
        if (parsed is List) {
          data = parsed;
        } else if (parsed is Map && parsed['defects'] != null) {
          data = parsed['defects'];
        } else if (parsed is Map && parsed['data'] != null) {
          data = parsed['data'];
        } else if (parsed is Map) {
          for (var v in parsed.values) {
            if (v is List) {
              data = v;
              break;
            }
          }
        }

        debugPrint('🔍 [결함 목록] 파싱된 결함 수: ${data.length}건');
        return data.map((json) => Defect.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 HTTP getDefects Error (결함 목록 조회 실패): $e');
      throw Exception('결함 목록 조회 실패: $e');
    }
  }

  // 15. 특정 결함 상세 조회 (GET /api/defects/<id>)
  Future<Defect?> getDefectDetail(int defectId) async {
    debugPrint('🔍 [결함 상세] ID: $defectId 조회');
    try {
      final response = await _dio.get('/api/defects/$defectId');
      if (response.statusCode == 200) {
        return Defect.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('🚨 HTTP getDefectDetail Error: $e');
      return null;
    }
  }

  // 16. 결함 삭제 (DELETE /api/defects/<id>) - 관리자 레벨 2 이상
  Future<bool> deleteDefect(int defectId) async {
    debugPrint('🗑️ [결함 삭제] 대상 ID: $defectId');
    try {
      final response = await _dio.delete('/api/defects/$defectId');
      debugPrint('✅ [결함 삭제] 상태코드: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('🚨 HTTP deleteDefect Error: $e');
      return false;
    }
  }

  // 17-A. 결함 등록 (POST /api/defects/)
  // 이미지가 있으면 /api/upload/에 먼저 업로드 → 받은 image_url을 결함 JSON에 포함해 등록
  Future<bool> createDefect({
    required int buildingId,
    required int deviceId,
    required String defectType,
    String? severity,
    String? comment,
    String? imageFilePath,
  }) async {
    debugPrint('📸 [결함 등록] 새 결함 등록 요청');
    try {
      String? uploadedImageUrl;

      // 1단계: 이미지 파일이 있으면 먼저 /api/upload/에 업로드
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        debugPrint('🖼️ [이미지 업로드] /api/upload/ 로 이미지 전송 중...');
        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              imageFilePath,
              filename: imageFilePath.split('/').last,
            ),
          });
          final uploadResponse = await _dio.post('/api/upload/', data: formData);
          if (uploadResponse.statusCode == 201 && uploadResponse.data != null) {
            uploadedImageUrl = uploadResponse.data['image_url']?.toString();
            debugPrint('✅ [이미지 업로드] 성공: $uploadedImageUrl');
          } else {
            debugPrint('⚠️ [이미지 업로드] 실패 (무시하고 이미지 없이 등록 진행)');
          }
        } catch (uploadError) {
          debugPrint('⚠️ [이미지 업로드] 오류 (무시하고 이미지 없이 등록 진행): $uploadError');
        }
      }

      // 2단계: 결함 JSON 등록 (image_url 포함)
      final Map<String, dynamic> data = {
        'building_id': buildingId,
        'device_id': deviceId,
        'defect_type': defectType,
        if (severity != null) 'severity': severity,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
      };
      final response = await _dio.post('/api/defects/', data: data);
      debugPrint('✅ [결함 등록] 상태코드: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 HTTP createDefect Error: $e');
      return false;
    }
  }


  // 16-1. 결함 메모(comment) 수정 (PATCH /api/defects/<id>)
  Future<bool> updateDefectComment(int defectId, String comment) async {
    debugPrint('📝 [결함 메모 수정] ID: $defectId, 코멘트: $comment');
    try {
      final response = await _dio.patch(
        '/api/defects/$defectId',
        data: {'comment': comment},
      );
      debugPrint('✅ [결함 메모 수정] 상태코드: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP updateDefectComment Error: $e');
      return false;
    }
  }

  // 사용자 수동 결함 전체 수정 (PUT)
  Future<bool> updateDefect({
    required int defectId,
    String? defectType,
    String? severity,
    String? comment,
    String? imageFilePath,
    int? buildingId,
  }) async {
    try {
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        // 이미지 있는 경우 multipart/form-data 전송
        final formData = FormData.fromMap({
          if (defectType != null) 'defect_type': defectType,
          if (severity != null) 'severity': severity,
          if (comment != null) 'comment': comment,
          if (buildingId != null) 'building_id': buildingId.toString(),
          'image': await MultipartFile.fromFile(imageFilePath, filename: imageFilePath.split('/').last),
        });
        final response = await _dio.put('/api/defects/$defectId', data: formData);
        return response.statusCode == 200;
      } else {
        // 이미지 없는 경우 JSON 전송
        final Map<String, dynamic> data = {};
        if (defectType != null) data['defect_type'] = defectType;
        if (severity != null) data['severity'] = severity;
        if (comment != null) data['comment'] = comment;
        if (buildingId != null) data['building_id'] = buildingId;

        final response = await _dio.put('/api/defects/$defectId', data: data);
        return response.statusCode == 200;
      }
    } catch (e) {
      debugPrint('🚨 HTTP updateDefect Error: $e');
      return false;
    }
  }

  // ==========================================

  // [Jetson 기기 상태(DeviceState) API]
  // 백엔드 Swagger: GET /api/device-states/{device_id}
  // ==========================================

  // 17. 특정 기기의 최신 상태 정보 조회
  Future<DeviceState?> getDeviceState(int deviceId) async {
    debugPrint('🔍 [기기 상태] ID: $deviceId 조회');
    try {
      final response = await _dio.get('/api/device-states/$deviceId');
      if (response.statusCode == 200) {
        return DeviceState.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('🚨 HTTP getDeviceState Error: $e');
      return null;
    }
  }

  // 17-1. 전체 장비 최신 상태 일괄 조회
  Future<List<DeviceState>> getAllDeviceStates() async {
    debugPrint('🔍 [전체 기기 상태] getAllDeviceStates 호출');
    try {
      final response = await _dio.get('/api/device-states/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DeviceState.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 HTTP getAllDeviceStates Error: $e');
      return [];
    }
  }

  // ==========================================
  // [사용자(User) 관리 API] - 조회, 수정, 삭제 (관리자 전용)
  // 백엔드 Swagger: /api/users/
  // ==========================================

  // 18. 전체 사용자 목록 조회 (GET /api/users/)
  Future<List<User>> getUsers() async {
    debugPrint('🔍 [유저 목록] getUsers 호출');
    try {
      final response = await _dio.get('/api/users/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 HTTP getUsers Error: $e');
      throw Exception('사용자 목록 조회 실패: $e');
    }
  }

  // 19. 특정 사용자 정보(비밀번호, 직급) 수정 (PUT /api/users/<id>)
  Future<bool> updateUser(String userId, {String? name, String? password, String? roleName}) async {
    debugPrint('📝 [유저 수정] 대상 ID: $userId');
    try {
      final Map<String, dynamic> data = {};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (roleName != null && roleName.isNotEmpty) data['role_name'] = roleName;

      final response = await _dio.put('/api/users/$userId', data: data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP updateUser Error: $e');
      return false;
    }
  }

  // 20. 특정 사용자 삭제 (DELETE /api/users/<id>)
  Future<bool> deleteUser(String userId) async {
    debugPrint('🗑️ [유저 삭제] 대상 ID: $userId');
    try {
      final response = await _dio.delete('/api/users/$userId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP deleteUser Error: $e');
      return false;
    }
  }

  // 21. 관리자 권한으로 새 사용자 등록 (POST /api/users/register)
  Future<bool> registerUserAsAdmin({required String email, required String password, required String name, required String roleName}) async {
    debugPrint('🧑‍💻 [유저 등록] 대상 이메일: $email, 직급: $roleName');
    try {
      final data = {
        'email': email,
        'password': password,
        'name': name,
        'role_name': roleName,
      };
      final response = await _dio.post('/api/users/register', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 HTTP registerUserAsAdmin Error: $e');
      return false;
    }
  }
}
