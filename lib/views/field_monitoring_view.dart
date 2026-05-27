import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';
import '../models/device_state.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
class FieldMonitoringView extends StatelessWidget {
  const FieldMonitoringView({super.key});

  // ─── 색상 토큰: AppColors 참조 ──────────────────────────
  static const Color _bgOffWhite   = AppColors.bgOffWhite;
  static const Color _cardWhite    = AppColors.cardWhite;
  static const Color _charcoal     = AppColors.charcoal;
  static const Color _lightGrey    = AppColors.lightGrey;
  static const Color _brandingBlue = AppColors.brandingBlue;
  static const Color _borderLight  = AppColors.borderLight;
  static const Color _green        = AppColors.statusGreen;
  static const Color _red          = AppColors.statusRed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgOffWhite,
      appBar: AppBar(
        backgroundColor: _cardWhite,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('현장 모니터링', 
                style: TextStyle(color: _charcoal, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _brandingBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandingBlue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, color: _brandingBlue, size: 14),
                SizedBox(width: 4),
                Text('실시간', 
                    style: TextStyle(color: _brandingBlue, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderLight, height: 1),
        ),
      ),
      body: Consumer<DeviceViewModel>(
        builder: (context, deviceVM, child) {
          final devices = deviceVM.devices;

          if (deviceVM.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _brandingBlue));
          }

          if (devices.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: _brandingBlue,
            onRefresh: () => deviceVM.fetchDevices(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // 1. 상단 요약 섹션
                _buildSummarySection(devices),
                const SizedBox(height: 32),
                
                // 2. 섹션 타이틀
                Row(
                  children: [
                    Container(
                      width: 4, height: 16,
                      decoration: BoxDecoration(color: _brandingBlue, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    const Text('장치별 현장 상태', 
                        style: TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 3. 장치별 카드 리스트
                ...devices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DeviceMonitorCardWidget(device: device),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  // 상단 요약 섹션 (대시보드 스타일의 통계 카드)
  Widget _buildSummarySection(List<Device> devices) {
    final online = devices.where((d) => d.isOnline).length;
    final offline = devices.length - online;
    
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('전체 장치', '${devices.length}', Icons.dns_outlined, _brandingBlue)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryCard('온라인', '$online', Icons.check_circle_outline, _green)),
        const SizedBox(width: 10),
        Expanded(child: _buildSummaryCard('오프라인', '$offline', Icons.error_outline, _red)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, 
              style: const TextStyle(color: _charcoal, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, 
              style: const TextStyle(color: _lightGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _cardWhite, shape: BoxShape.circle, border: Border.all(color: _borderLight)),
            child: const Icon(Icons.sensors_off_rounded, color: _lightGrey, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('활성화된 장치가 없습니다', 
              style: TextStyle(color: _charcoal, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('장치 관리 메뉴에서 새로운 AI 단말기를 등록하세요.', 
              style: TextStyle(color: _lightGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _brandingBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('대시보드로 돌아가기', 
                  style: TextStyle(color: _brandingBlue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// 실시간 데이터를 연동하기 위해 개별 카드를 StatefulWidget으로 분리
class DeviceMonitorCardWidget extends StatefulWidget {
  final Device device;
  const DeviceMonitorCardWidget({super.key, required this.device});

  @override
  State<DeviceMonitorCardWidget> createState() => _DeviceMonitorCardWidgetState();
}

class _DeviceMonitorCardWidgetState extends State<DeviceMonitorCardWidget> {
  DeviceState? _currentState;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchState();
    // 5초 주기로 최신 상태 가져오기
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchState());
  }

  Future<void> _fetchState() async {
    if (!mounted) return;
    try {
      final state = await ApiService().getDeviceState(widget.device.id);
      if (mounted) setState(() => _currentState = state);
    } catch (e) {
      // 에러 시 무시
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    // 실제 데이터 바인딩 (없을 경우 0.0)
    final temp = _currentState?.temperatureCpu ?? 0.0;
    final cpuUsage = _currentState?.cpuUsage ?? 0.0;
    final gpuUsage = _currentState?.gpuUsage ?? 0.0;
    
    // 온도가 60도 이상이거나 CPU/GPU가 90% 이상일 때 위험
    final isAlert = temp >= 60.0 || cpuUsage >= 90.0 || gpuUsage >= 90.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? AppColors.statusOrange.withValues(alpha: 0.6) : AppColors.borderLight,
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAlert ? AppColors.statusOrange.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? AppColors.statusGreen : AppColors.lightGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.deviceName, 
                              style: const TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.lightGrey, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(device.location, 
                                    style: const TextStyle(color: AppColors.lightGrey, fontSize: 11, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: device.isOnline ? AppColors.statusGreen.withValues(alpha: 0.1) : AppColors.bgOffWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: device.isOnline ? AppColors.statusGreen.withValues(alpha: 0.3) : AppColors.borderLight),
                ),
                child: Text(
                  device.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(color: device.isOnline ? AppColors.statusGreen : AppColors.lightGrey, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 실시간 센서/시스템 리소스 그리드 영역 (기존 습도/진동 -> CPU/GPU 사용량으로 변경)
          if (device.isOnline && _currentState != null) ...[
            Row(
              children: [
                Expanded(child: _buildSensorBox(Icons.thermostat_rounded, '코어 온도', '${temp.toStringAsFixed(1)}°C', temp >= 60 ? AppColors.statusRed : AppColors.brandingBlue)),
                const SizedBox(width: 10),
                Expanded(child: _buildSensorBox(Icons.memory_rounded, 'CPU 사용', '${cpuUsage.toStringAsFixed(0)}%', cpuUsage >= 90 ? AppColors.statusOrange : AppColors.brandingBlue)),
                const SizedBox(width: 10),
                Expanded(child: _buildSensorBox(Icons.developer_board_rounded, 'GPU 사용', '${gpuUsage.toStringAsFixed(0)}%', gpuUsage >= 90 ? AppColors.statusOrange : AppColors.statusGreen)),
              ],
            ),
          ] else ...[
            // 오프라인이거나 데이터 대기 중일 때
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  device.isOnline ? '장치 상태를 불러오는 중...' : '오프라인 장치입니다. 상태 수신 불가',
                  style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
                ),
              ),
            ),
          ],
          
          if (isAlert && device.isOnline) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.statusOrange.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.statusOrange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '비정상 온도/과부하 감지: 쿨링 상태 확인이 권고됩니다.',
                      style: TextStyle(color: AppColors.statusOrange, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),
          
          // 하단 정보 (MAC, Last Connected)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: ${device.macAddress}', 
                  style: const TextStyle(color: AppColors.lightGrey, fontSize: 10, fontWeight: FontWeight.w500)),
              Text('Last Sync: ${device.isOnline && _currentState != null ? "최근 수신됨" : device.lastConnectedAt}', 
                  style: const TextStyle(color: AppColors.lightGrey, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgOffWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, 
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, 
              style: const TextStyle(color: AppColors.lightGrey, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

}
