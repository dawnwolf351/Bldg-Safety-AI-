import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 사용자 목록 불러오기
  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _apiService.getUsers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 직급/이름/비밀번호 변경
  Future<bool> updateUser(String userId, {String? name, String? password, String? roleName}) async {
    final success = await _apiService.updateUser(userId, name: name, password: password, roleName: roleName);
    if (success) {
      // 로컬 리스트 업데이트 대신 전체를 새로고침하여 최신 상태 동기화
      await fetchUsers();
    }
    return success;
  }

  // 사용자 삭제
  Future<bool> deleteUser(String userId) async {
    final success = await _apiService.deleteUser(userId);
    if (success) {
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
    }
    return success;
  }

  // 관리자 권한으로 새 사용자 등록
  Future<bool> registerUserAsAdmin({required String email, required String password, required String name, required String roleName}) async {
    final success = await _apiService.registerUserAsAdmin(email: email, password: password, name: name, roleName: roleName);
    if (success) {
      await fetchUsers(); // 등록 성공 시 목록 갱신
    }
    return success;
  }
}
