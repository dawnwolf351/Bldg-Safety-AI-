import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_colors.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // ─── 색상 토큰 ──────────────────────────────────────────────
  static const Color _bgOffWhite  = AppColors.bgOffWhite;       // 0xFFF8F9FA
  static const Color _cardWhite   = AppColors.cardWhite;         // 0xFFFFFFFF
  // 설정 화면만의 고유 색상 (조금 더 진한 턴로 설계됨)
  static const Color _charcoal    = Color(0xFF1A1D21);
  static const Color _lightGrey   = Color(0xFF6B7280);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _blue        = Color(0xFF2563EB);

  // 기기 IP: viewModel에서 불러온 값을 표시용으로만 사용
  String _displayIp = '불러오는 중...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<SettingsViewModel>(context, listen: false);
      setState(() {
        _displayIp = vm.droneIp.isNotEmpty ? vm.droneIp : '192.168.1.100';
      });
    });
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm     = context.watch<AuthViewModel>();
    final user       = authVm.currentUser;

    final roleKo = user?.role == 'super_admin'
        ? '최고관리자'
        : (user?.role == 'admin' ? '현장 관리자' : '일반 사용자');

    return Scaffold(
      backgroundColor: _bgOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(
                      user?.name  ?? '테스트 유저',
                      user?.email ?? 'user@example.com',
                      roleKo,
                    ),
                    const SizedBox(height: 32),
                    _sectionLabel('제품 사용과 관리'),
                    const SizedBox(height: 10),
                    _buildDeviceSection(),
                    const SizedBox(height: 32),
                    _sectionLabel('알림 설정'),
                    const SizedBox(height: 10),
                    _buildNotificationSection(settingsVm),
                    const SizedBox(height: 32),
                    _sectionLabel('앱 정보'),
                    const SizedBox(height: 10),
                    _buildAppInfoSection(settingsVm),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 헤더 ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.settings_outlined, color: _blue, size: 26),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정', style: TextStyle(color: _charcoal, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 섹션 레이블 ──────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: const TextStyle(color: _lightGrey, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
    );
  }

  // ─── 공통 카드 래퍼 ──────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  // ─── 프로필 카드 ──────────────────────────────────────────────
  Widget _buildProfileCard(String name, String email, String roleKo) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _blue.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 36, color: _blue),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(color: _charcoal, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: _lightGrey, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(roleKo, style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 단말기 접속 주소 (IP 자동 표시, 포트 없음) ──────────────
  Widget _buildDeviceSection() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_rounded, color: _blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('단말기 접속 주소', style: TextStyle(color: _charcoal, fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('시스템이 디바이스의 IP를 자동으로 감지합니다.', style: TextStyle(color: _lightGrey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _bgOffWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: _lightGrey, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayIp,
                      style: const TextStyle(color: _charcoal, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('자동 감지됨', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 알림 설정 (기존 로직 유지) ───────────────────────────────
  Widget _buildNotificationSection(SettingsViewModel vm) {
    return _card(
      child: Column(
        children: [
          _switchTile(
            icon: Icons.notification_important_rounded,
            title: '긴급 푸시 알림',
            subtitle: '치명적 결함 발견 시 실시간 팝업 알림',
            value: vm.pushNotifications,
            onChanged: vm.togglePushNotifications,
          ),
          const Divider(color: _borderLight, height: 1, indent: 56, endIndent: 20),
          _switchTile(
            icon: Icons.vibration_rounded,
            title: '소리 및 진동 알림',
            subtitle: '위험 경고 시 강력한 진동과 경고음',
            value: vm.soundVibration,
            onChanged: vm.toggleSoundVibration,
          ),
          const Divider(color: _borderLight, height: 1, indent: 56, endIndent: 20),
          _switchTile(
            icon: Icons.nightlight_round,
            title: '야간 방해금지',
            subtitle: '야간 시간대(22:00~07:00) 알림 무음',
            value: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _bgOffWhite, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _charcoal, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: _charcoal, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(subtitle, style: const TextStyle(color: _lightGrey, fontSize: 12)),
        ),
        activeTrackColor: _blue,
        activeThumbColor: Colors.white,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: _borderLight,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  // ─── 앱 정보 (진단 보고서 삭제됨) ────────────────────────────
  Widget _buildAppInfoSection(SettingsViewModel vm) {
    return _card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _bgOffWhite, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.info_outline_rounded, color: _charcoal, size: 22),
        ),
        title: const Text('앱 버전 정보', style: TextStyle(color: _charcoal, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Text('현재 버전 v1.0.0 (최신 빌드)', style: TextStyle(color: _lightGrey, fontSize: 12)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _borderLight),
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: '건축물 구조 안전 진단 시스템',
            applicationVersion: 'v1.0.0',
            applicationLegalese: 'Copyright 2026. Antigravity AI.',
          );
        },
      ),
    );
  }
}
