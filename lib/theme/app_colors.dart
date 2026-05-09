import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 공통 색상 팔레트
/// 모든 뷰(View)는 이 파일에서 색상을 참조합니다.
abstract class AppColors {
  // ── 배경/카드 ──────────────────────────────
  static const Color bgOffWhite  = Color(0xFFF8F9FA);
  static const Color cardWhite   = Color(0xFFFFFFFF);

  // ── 텍스트 ────────────────────────────────
  static const Color charcoal    = Color(0xFF212529);
  static const Color lightGrey   = Color(0xFF6C757D);

  // ── 브랜드/포인트 ─────────────────────────
  static const Color brandingBlue = Color(0xFF3761F3);
  static const Color borderLight  = Color(0xFFDEE2E6);

  // ── 상태 색상 ────────────────────────────
  static const Color statusGreen  = Color(0xFF22C55E);
  static const Color statusRed    = Color(0xFFEF4444);
  static const Color statusOrange = Color(0xFFFFB020);
}
