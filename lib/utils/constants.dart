// API 주소나 고정된 문자열, 크기 등 전역 상수를 모아두는 파일입니다.
class AppConstants {
  static const String appTitle = '건축물 구조 안전 진단 시스템';
  static const String apiBaseUrl = 'https://api.example.com/v1';
  static const String dummyTokenKey = 'jwt_token';
  
  // 기타 에러 메시지
  static const String networkError = '네트워크 연결 상태를 확인해주세요.';
  static const String loginError = '로그인 정보가 올바르지 않습니다.';
}
