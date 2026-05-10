import 'package:flutter/material.dart';
import '../models/building.dart';
import '../services/api_service.dart';

class BuildingViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Building> _buildings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Building> get buildings => _buildings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 전체 건물 목록 조회 (GET /api/buildings/)
  Future<void> fetchBuildings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _buildings = await _apiService.getBuildings();
    } catch (e) {
      _errorMessage = '건물 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 건물 추가 (POST /api/buildings/)
  Future<bool> addBuilding(String name, String location, String? completionDate) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.addBuilding(name, location, completionDate);

    if (success) {
      await fetchBuildings(); // 추가 성공 시 목록 새로고침
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  // 건물 수정 (PUT /api/buildings/<id>)
  Future<bool> updateBuilding(int id, String name, String location, String? completionDate) async {
    final success = await _apiService.updateBuilding(id, name, location, completionDate);
    if (success) await fetchBuildings();
    return success;
  }

  // 건물 삭제 (DELETE /api/buildings/<id>)
  Future<bool> deleteBuilding(int id) async {
    final success = await _apiService.deleteBuilding(id);
    if (success) await fetchBuildings();
    return success;
  }
}
