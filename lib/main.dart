import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'utils/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/device_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'utils/globals.dart';

// 앱의 시작점(Entry Point)입니다.
void main() {
  // 아이폰 실기기에서 네이티브 플러그인(보안 저장소, 동영상 플레이어 등) 초기화 전 멈춤 현상(흰 화면) 방지
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 실행 시 기본 방향을 세로(Portrait)로 고정
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // media_kit RTSP 스트리밍 엔진 초기화 (flutter_vlc_player 대체)
  MediaKit.ensureInitialized();
  
  runApp(
    // 1. 상태 관리를 위해 앱의 최상단에 Provider들을 등록합니다.
    // 이렇게 하면 앱의 어느 화면에서든 해당 ViewModel에 접근할 수 있습니다.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => DeviceViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const CapstoneApp(),
    ),
  );
}

class CapstoneApp extends StatelessWidget {
  const CapstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건축물 구조 안전 진단 시스템',
      // utils 폴더에서 정의해둔 디자인 테마를 가져와 적용합니다.
      theme: AppTheme.lightTheme,
      
      // 앱 내 어디서든 Context 없이 화면 이동/팝업을 띄우기 위한 글로벌 키 적용
      navigatorKey: globalNavKey,

      // 2. AuthViewModel 에 접근하여 로그인 여부를 확인합니다.
      home: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // 인증되었다면 대시보드 화면을 띄우고, 아니라면 로그인 화면을 띄웁니다.
          if (authViewModel.isAuthenticated) {
            return const DashboardView();
          } else {
            return const LoginView();
          }
        },
      ),
      // 우측 상단 'DEBUG' 띠 모양을 없애줍니다.
      debugShowCheckedModeBanner: false,
    );
  }
}
