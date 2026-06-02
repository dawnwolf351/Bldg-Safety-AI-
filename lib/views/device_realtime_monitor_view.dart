import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_state.dart';
import '../models/device.dart';
import '../theme/app_colors.dart';
import '../viewmodels/dashboard_viewmodel.dart';

/// 장비 실시간 상태 상세 모니터링 화면
/// - 각 메트릭별 실시간 라인 차트
/// - 대시보드 뷰모델의 히스토리 데이터를 공유받아 이전 데이터 누락 없이 표시
class DeviceRealTimeMonitorView extends StatelessWidget {
  final Device device;
  const DeviceRealTimeMonitorView({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.deviceName,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
            const Text('실시간 상태 모니터링',
              style: TextStyle(color: AppColors.lightGrey, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandingBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandingBlue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, color: AppColors.brandingBlue, size: 13),
                SizedBox(width: 4),
                Text('5초 갱신 (실시간)', style: TextStyle(color: AppColors.brandingBlue, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, dashVM, child) {
          final history = dashVM.deviceStateHistory[device.id] ?? [];
          final latest = history.isNotEmpty
              ? history.last
              : DeviceState(
                  id: 0,
                  deviceId: device.id,
                  recordedAt: null,
                  cpuUsage: 0.0,
                  gpuUsage: 0.0,
                  gpuMemoryUsage: 0.0,
                  ramUsage: 0.0,
                  temperatureSoc: 0.0,
                  temperatureCpu: 0.0,
                  temperatureGpu: 0.0,
                  inferenceFps: 0.0,
                  modelName: '알 수 없음',
                  cameraStatus: '오프라인',
                  depthSensorStatus: '오프라인',
                );

          // 차트 데이터 변환 (기존 로직 유지, 빈 배열은 _buildChartCard에서 처리)
          final cpuData = history.map((e) => e.cpuUsage).toList();
          final gpuData = history.map((e) => e.gpuUsage).toList();
          final ramData = history.map((e) => e.ramUsage).toList();
          final tempSocData = history.map((e) => e.temperatureSoc).toList();
          final tempCpuData = history.map((e) => e.temperatureCpu).toList();
          final tempGpuData = history.map((e) => e.temperatureGpu).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── 그래프 6개 ───────────────────────────────────
              _buildChartCard('CPU 사용률', cpuData, Colors.green, '%', 100),
              _buildChartCard('GPU 사용률', gpuData, Colors.deepPurple, '%', 100),
              _buildChartCard('RAM 사용률', ramData, Colors.teal, '%', 100),
              _buildChartCard('SoC 온도', tempSocData, Colors.orange, '℃', 100),
              _buildChartCard('CPU 온도', tempCpuData, Colors.orangeAccent, '℃', 100),
              _buildChartCard('GPU 온도', tempGpuData, Colors.red, '℃', 100),

              // ── 추가 정보 (FPS, 모델, 카메라, 센서) ──────────
              const SizedBox(height: 4),
              _buildExtraInfoCard(latest),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // 실시간 라인 차트 카드
  Widget _buildChartCard(String title, List<double> rawData, Color color, String unit, double maxY) {
    // 빈 데이터 처리 및 1개일 때의 처리 (LineChart는 점 2개 이상 필요)
    List<double> data = rawData.isEmpty ? [0.0, 0.0] : List.from(rawData);
    if (data.length == 1) data = [data[0], data[0]];

    final displayValue = rawData.isEmpty ? '-' : '${data.last.toStringAsFixed(1)}$unit';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.charcoal, fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rawData.isEmpty ? AppColors.borderLight : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(color: rawData.isEmpty ? AppColors.lightGrey : color, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}$unit',
                              style: const TextStyle(color: AppColors.lightGrey, fontSize: 8),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].clamp(0, maxY))),
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 추가 정보 카드 (FPS, 모델, 카메라, 센서)
  Widget _buildExtraInfoCard(DeviceState s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.brandingBlue, size: 16),
              SizedBox(width: 8),
              Text('AI 추론 & 센서 상태', style: TextStyle(color: AppColors.charcoal, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('추론 FPS', s.inferenceFps != null ? '${s.inferenceFps!.toStringAsFixed(1)} fps' : '--', Colors.deepPurple),
          const SizedBox(height: 8),
          _infoRow('AI 모델명', s.modelName ?? '--', AppColors.brandingBlue),
          const SizedBox(height: 8),
          _infoRow('카메라 상태', s.cameraStatus ?? '--', s.cameraStatus == 'OK' ? Colors.green : Colors.redAccent),
          const SizedBox(height: 8),
          _infoRow('깊이 센서', s.depthSensorStatus ?? '--', s.depthSensorStatus == 'OK' ? Colors.green : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.lightGrey, fontSize: 12, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
