import 'package:flutter/material.dart';
import 'dart:async';
import '../models/defect.dart';
import '../services/api_service.dart';
import '../utils/globals.dart';
import '../utils/alert_utils.dart';
import '../services/notification_service.dart';

/// 진단 이력(결함) 데이터를 관리하는 ViewModel
/// DeviceViewModel과 동일한 패턴 (폴링, 에러 처리, CRUD)
class InspectionViewModel extends ChangeNotifier {
  List<Defect> _defects = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer; // 실시간 동기화를 위한 타이머

  List<Defect> get defects => _defects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  InspectionViewModel() {
    _defects = [];
    startPolling(); // 생성 시 폴링 시작
  }

  // 15초마다 서버에서 결함 데이터를 새로 긁어오는 폴링
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _silentFetch();
    });
  }

  Future<void> _silentFetch() async {
    try {
      final latest = await ApiService().getDefects();
      // 데이터가 실제로 변했을 때만 UI 갱신 및 새로운 위험 알림 체크
      if (_isDefectListChanged(latest)) {
        
        // 새로 추가된 결함 필터링 (기존 _defects 에 없는 항목들)
        final newDefects = latest.where((l) => !_defects.any((d) => d.defectId == l.defectId)).toList();
        
        // 새로 추가된 결함 중 심각도가 CRITICAL(E등급) 또는 WARNING(D등급)인 것이 있는지 확인
        final newAlertDefects = newDefects.where((d) => d.statusCode == 'CRITICAL' || d.statusCode == 'WARNING').toList();

        _defects = latest;
        notifyListeners();

        // 만약 새로운 위험/주의 결함이 감지되었다면 실시간으로 알림 팝업 띄우기
        if (newAlertDefects.isNotEmpty) {
          for (var alertDefect in newAlertDefects) {
            String buildingName = "건물명 미상";
            String location = "위치 미상";
            
            try {
              // 건물 정보를 가져와 매칭 (API 호출 부하를 줄이기 위해 보통은 캐싱된 데이터를 쓰지만, 여기서는 실시간 긴급 알림이므로 직접 조회)
              final buildings = await ApiService().getBuildings();
              final targetBuilding = buildings.firstWhere((b) => b.id == alertDefect.buildingId);
              buildingName = targetBuilding.buildingName;
              location = targetBuilding.location;
            } catch (_) {
              // 찾지 못해도 기본값으로 진행
            }

            final gradeStr = alertDefect.statusCode == 'CRITICAL' ? '긴급 위험(E)' : '주의(D)';
            final gradeLabel = alertDefect.severity ?? "심각";

            // iOS/AOS 시스템 알림 즉시 발송
            await NotificationService().showEmergencyNotification(
              title: '🚨 $gradeStr 감지!',
              body: '[$buildingName / $location]\n${alertDefect.defectType} ($gradeLabel) 결함이 자동 탐지되었습니다. 즉각 확인하세요.',
            );
          }

          // 앱 내 팝업도 동시에 표시 (마지막 알림 기준 1회만)
          final context = globalNavKey.currentContext;
          if (context != null && context.mounted) {
            EmergencyAlert.show(context);
          }
        }
      }
    } catch (e) {
      // 폴링 중 에러는 조용히 무시
    }
  }

  // 결함 목록이 실제로 변경되었는지 비교
  bool _isDefectListChanged(List<Defect> latest) {
    if (latest.length != _defects.length) return true;
    for (int i = 0; i < latest.length; i++) {
      if (latest[i].defectId != _defects[i].defectId ||
          latest[i].severity != _defects[i].severity ||
          latest[i].comment != _defects[i].comment) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // 메모리 누수 방지
    super.dispose();
  }

  // 데이터 fetch (실제 API DB 데이터 긁어오기)
  Future<void> fetchDefects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _defects = await ApiService().getDefects();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // DB에서 결함 삭제 통신 후 성공 시 화면 새로고침
  Future<bool> deleteDefect(int defectId) async {
    final success = await ApiService().deleteDefect(defectId);
    if (success) {
      await fetchDefects();
      return true;
    } else {
      _errorMessage = '서버에서 결함 이력을 삭제하는데 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  // 새 결함 탐지 이력 등록 후 성공 시 목록 자동 새로고침
  Future<bool> addDefect({
    required int buildingId,
    required int deviceId,
    required String defectType,
    String? severity,
    String? comment,
    String? imageFilePath,
  }) async {
    final success = await ApiService().createDefect(
      buildingId: buildingId,
      deviceId: deviceId,
      defectType: defectType,
      severity: severity,
      comment: comment,
      imageFilePath: imageFilePath,
    );
    if (success) {
      await fetchDefects(); // 등록 성공 시 목록 자동 새로고침
      return true;
    } else {
      _errorMessage = '결함 이력을 등록하는데 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  // 기존 결함 코멘트 수정 후 모델 즉시 갱신 (단순 패치)
  Future<bool> updateDefectComment(int defectId, String newComment) async {
    final success = await ApiService().updateDefectComment(defectId, newComment);
    if (success) {
      // 로컬 메모리 목록에서도 해당 항목 찾아 코멘트 갱신
      final idx = _defects.indexWhere((d) => d.defectId == defectId);
      if (idx != -1) {
        _defects[idx] = _defects[idx].copyWith(comment: newComment);
        notifyListeners();
      }
      return true;
    }
    return false;
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
    final success = await ApiService().updateDefect(
      defectId: defectId,
      defectType: defectType,
      severity: severity,
      comment: comment,
      imageFilePath: imageFilePath,
      buildingId: buildingId,
    );
    if (success) {
      await fetchDefects(); // 새로고침
      return true;
    } else {
      _errorMessage = '결함 이력을 수정하는데 실패했습니다.';
      notifyListeners();
      return false;
    }
  }
}
