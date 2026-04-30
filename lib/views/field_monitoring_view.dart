import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';

class FieldMonitoringView extends StatelessWidget {
  const FieldMonitoringView({super.key});

  static const Color _navy = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFFFB020);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현장 모니터링', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('FIELD MONITORING', style: TextStyle(color: _cyan, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, color: _cyan, size: 14),
                SizedBox(width: 4),
                Text('실시간', style: TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<DeviceViewModel>(
        builder: (context, deviceVM, child) {
          final devices = deviceVM.devices;

          if (deviceVM.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _cyan));
          }

          if (devices.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: _cyan,
            backgroundColor: _card,
            onRefresh: () => deviceVM.fetchDevices(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(20),
              children: [
                // 상단 요약 카드
                _buildSummaryRow(devices),
                const SizedBox(height: 24),
                // 섹션 타이틀
                const Text('장치별 현장 상태', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('DEVICE FIELD STATUS', style: TextStyle(color: _cyan, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 16),
                // 장치별 모니터링 카드
                ...devices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDeviceMonitorCard(device),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  // 상단 요약 3카드
  Widget _buildSummaryRow(List<Device> devices) {
    final online = devices.where((d) => d.isOnline).length;
    final offline = devices.length - online;
    return Row(
      children: [
        Expanded(child: _buildMiniStat(Icons.devices, '전체 장치', '${devices.length}', _cyan)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.check_circle_outline, '온라인', '$online', _green)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.error_outline, '오프라인', '$offline', _red)),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  // 장치별 모니터링 카드
  Widget _buildDeviceMonitorCard(Device device) {
    // 더미 센서 데이터 (장치마다 고유하게 생성)
    final temp = 22.0 + (device.id % 10) * 1.5;
    final humidity = 45.0 + (device.id % 8) * 3.0;
    final vibration = (device.id % 5) * 0.3;
    final isAlert = vibration > 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? _orange.withValues(alpha: 0.5) : Colors.blueGrey.withValues(alpha: 0.15),
        ),
        boxShadow: isAlert
            ? [BoxShadow(color: _orange.withValues(alpha: 0.1), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 장치명 + 상태
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? _green : Colors.grey[600],
                        boxShadow: device.isOnline
                            ? [BoxShadow(color: _green.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.deviceName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey[500], size: 11),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(device.location, style: TextStyle(color: Colors.grey[500], fontSize: 11), overflow: TextOverflow.ellipsis),
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
                  color: device.isOnline ? _green.withValues(alpha: 0.1) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: device.isOnline ? _green.withValues(alpha: 0.4) : Colors.grey[700]!),
                ),
                child: Text(
                  device.isOnline ? '모니터링 중' : '연결 끊김',
                  style: TextStyle(color: device.isOnline ? _green : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 센서 데이터 그리드
          Row(
            children: [
              Expanded(child: _buildSensorTile(Icons.thermostat, '온도', '${temp.toStringAsFixed(1)}°C', temp > 30 ? _red : _cyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildSensorTile(Icons.water_drop, '습도', '${humidity.toStringAsFixed(0)}%', humidity > 70 ? _orange : _cyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildSensorTile(Icons.vibration, '진동', '${vibration.toStringAsFixed(1)}mm/s', isAlert ? _red : _green)),
            ],
          ),
          if (isAlert) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '진동 수치가 기준치를 초과했습니다. 현장 확인이 필요합니다.',
                      style: TextStyle(color: _orange.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 하단 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MAC: ${device.macAddress}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              Text('마지막 연결: ${device.lastConnectedAt}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, color: Colors.grey[700], size: 64),
          const SizedBox(height: 20),
          Text('등록된 장치가 없습니다', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('장치 관리에서 AI 단말을 먼저 등록해주세요', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: _cyan, size: 16),
            label: const Text('대시보드로 돌아가기', style: TextStyle(color: _cyan, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _cyan.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}
