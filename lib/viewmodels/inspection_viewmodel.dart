import 'package:flutter/material.dart';
import 'dart:async';
import '../models/defect.dart';
import '../services/api_service.dart';

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
      // 데이터가 실제로 변했을 때만 UI 갱신
      if (_isDefectListChanged(latest)) {
        _defects = latest;
        notifyListeners();
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
}
