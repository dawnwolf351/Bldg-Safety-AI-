import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<SettingsViewModel>(context, listen: false);
      _ipController.text = vm.droneIp;
      _portController.text = vm.dronePort;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  final Color _navyCard = const Color(0xFF1E293B);
  final Color _cyanAccent = const Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return SafeArea(
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
                  _buildProfileSection(
                    user?.name ?? '테스트 유저', 
                    user?.role == 'admin' ? '현장 관리자' : '일반 사용자',
                    user?.role == 'admin' ? 'FIELD ADMIN' : 'GENERAL USER'
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('장치 및 AI 설정', 'DEVICE & AI CONFIG', Icons.memory),
                  const SizedBox(height: 12),
                  _buildDeviceAiConfigSection(settingsVm),
                  const SizedBox(height: 24),
                  _buildSectionTitle('알림 설정', 'NOTIFICATION SETTINGS', Icons.notifications_none),
                  const SizedBox(height: 12),
                  _buildNotificationSection(settingsVm),
                  const SizedBox(height: 24),
                  _buildSectionTitle('데이터 및 시스템', 'DATA & SYSTEM', Icons.storage_outlined),
                  const SizedBox(height: 12),
                  _buildDataSystemSection(settingsVm),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.settings_outlined, color: _cyanAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('설정', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('SYSTEM CONFIGURATION', style: TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titleKo, String titleEn, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: _cyanAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(titleKo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(titleEn, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileSection(String name, String roleKo, String roleEn) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _cyanAccent.withValues(alpha: 0.15),
              child: Icon(Icons.person_outline, size: 32, color: _cyanAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roleKo, style: TextStyle(color: _cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(roleEn, style: TextStyle(color: _cyanAccent.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.edit_outlined, color: Colors.blueGrey[300]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceAiConfigSection(SettingsViewModel vm) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('단말기 접속 주소', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Drone / Jetson IP Config', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(_ipController, 'IP 주소', Icons.language),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(_portController, '포트', null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  vm.updateDroneConfig(_ipController.text, _portController.text);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('단말기 접속 주소가 저장되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: _cyanAccent));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyanAccent.withValues(alpha: 0.15),
                  foregroundColor: _cyanAccent,
                  elevation: 0,
                  side: BorderSide(color: _cyanAccent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('설정 저장', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(color: Colors.blueGrey, height: 32, thickness: 0.2),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('AI 탐지 임계값', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Detection Threshold', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text('결함 탐지 민감도를 조절합니다. (값이 낮을수록 작은 결함도 감지함)', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${(vm.aiThreshold * 100).toInt()}%', style: TextStyle(color: _cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _cyanAccent,
                      inactiveTrackColor: _cyanAccent.withValues(alpha: 0.2),
                      thumbColor: _cyanAccent,
                      overlayColor: _cyanAccent.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: vm.aiThreshold,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        vm.updateAiThreshold(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData? icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey[400], size: 18) : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _cyanAccent),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(SettingsViewModel vm) {
    return _buildCard(
      child: Column(
        children: [
          _buildSwitchTile(
            titleKo: '긴급 푸시 알림',
            titleEn: 'Push Notifications',
            subtitle: '치명적 결함 발견 시 실시간으로 팝업 알림을 받습니다.',
            icon: Icons.notification_important_outlined,
            value: vm.pushNotifications,
            onChanged: (val) => vm.togglePushNotifications(val),
          ),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.2), height: 1),
          _buildSwitchTile(
            titleKo: '소리 및 진동 알림',
            titleEn: 'Sound & Vibration',
            subtitle: '위험 경고 시 강력한 진동과 경고음을 발생시킵니다.',
            icon: Icons.vibration_outlined,
            value: vm.soundVibration,
            onChanged: (val) => vm.toggleSoundVibration(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({required String titleKo, required String titleEn, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return SwitchListTile(
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(titleKo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(titleEn, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
      ),
      secondary: Icon(icon, color: Colors.blueGrey[300]),
      activeThumbColor: _cyanAccent,
      activeTrackColor: _cyanAccent.withValues(alpha: 0.3),
      inactiveThumbColor: Colors.blueGrey[400],
      inactiveTrackColor: Colors.black.withValues(alpha: 0.3),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDataSystemSection(SettingsViewModel vm) {
    return _buildCard(
      child: Column(
        children: [
          _buildListTile(
            titleKo: '진단 보고서 내보내기',
            titleEn: 'Export Inspection Report',
            subtitle: '최근 진단된 데이터를 PDF 또는 엑셀 형식으로 추출합니다.',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보고서를 생성하는 중...'), backgroundColor: Colors.blueGrey));
              await vm.exportReport();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('보고서 다운로드가 완료되었습니다.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: _cyanAccent));
            },
          ),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.2), height: 1),
          _buildListTile(
            titleKo: '저장소 캐시 정리',
            titleEn: 'Clear Cache',
            subtitle: '기기에 저장된 임시 진단 영상 데이터를 삭제하여 용량을 비웁니다.',
            icon: Icons.cleaning_services_outlined,
            onTap: () async {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('캐시 데이터를 지우는 중...'), backgroundColor: Colors.blueGrey));
               await vm.clearCache();
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('임시 데이터가 삭제되었습니다.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: _cyanAccent));
            },
          ),
          Divider(color: Colors.blueGrey.withValues(alpha: 0.2), height: 1),
          _buildListTile(
            titleKo: '앱 버전 정보',
            titleEn: 'App Info',
            subtitle: '현재 버전 v1.0.0 (최신 빌드)\n오픈소스 라이선스 확인',
            icon: Icons.info_outline,
            onTap: () {
               showAboutDialog(
                 context: context,
                 applicationName: '건축물 구조 안전 진단 시스템',
                 applicationVersion: 'v1.0.0',
                 applicationLegalese: 'Copyright 2026. Antigravity AI.',
               );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required String titleKo, required String titleEn, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(titleKo, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(titleEn, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
      ),
      leading: Icon(icon, color: Colors.blueGrey[300]),
      trailing: Icon(Icons.chevron_right, color: Colors.blueGrey[600]),
      onTap: onTap,
    );
  }

  // 로그아웃 버튼 제거됨 (하위 네비게이션 바로 이관)
}
