import 'package:flutter/material.dart';

// 앱 전역에서 Navigation(화면 전환)과 context(다이얼로그/스낵바)를 사용하기 위한 글로벌 키입니다.
// ViewModel 등 UI 계층 바깥에서 팝업을 강제 호출하거나, 로그아웃 시 강제 화면 이탈을 제어할 때 사용됩니다.
final GlobalKey<NavigatorState> globalNavKey = GlobalKey<NavigatorState>();
