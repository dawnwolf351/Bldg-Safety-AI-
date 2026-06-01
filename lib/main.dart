import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'utils/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/device_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/building_viewmodel.dart';
import 'viewmodels/inspection_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'utils/globals.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  MediaKit.ensureInitialized();
  
  // 알림 서비스 초기화 (알림 권한 요청 포함)
  await NotificationService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => DeviceViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => BuildingViewModel()),
        ChangeNotifierProvider(create: (_) => InspectionViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
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
      theme: AppTheme.lightTheme,
      
      navigatorKey: globalNavKey,

      home: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return authViewModel.isAuthenticated
              ? const DashboardView()
              : const LoginView();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
