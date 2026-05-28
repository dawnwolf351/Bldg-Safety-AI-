import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/device_state.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// 장비 실시간 상태 상세 모니터링 화면
/// - 각 메트릭별 실시간 라인 차트
/// - 5초 주기 자동 갱신
class DeviceRealTimeMonitorView extends StatefulWidget {
  final Device device;
  const DeviceRealTimeMonitorView({super.key, required this.device});

  @override
  State<DeviceRealTimeMonitorView> createState() => _DeviceRealTimeMonitorViewState();
}

class _DeviceRealTimeMonitorViewState extends State<DeviceRealTimeMonitorView> {
  final ApiService _api = ApiService();
  Timer? _timer;
  DeviceState? _latest;

  // 각 메트릭별 최근 20개 포인트 이력
  final List<double> _cpuHistory    = [];
  final List<double> _gpuHistory    = [];
  final List<double> _ramHistory    = [];
  final List<double> _tempSocHistory = [];
  final List<double> _tempCpuHistory = [];
  final List<double> _tempGpuHistory = [];

  static const int _maxPoints = 20;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  Future<void> _fetch() async {
    final state = await _api.getDeviceState(widget.device.id);
    if (!mounted || state == null) return;
    setState(() {
      _latest = state;
      _addPoint(_cpuHistory,     state.cpuUsage);
      _addPoint(_gpuHistory,     state.gpuUsage);
      _addPoint(_ramHistory,     state.ramUsage);
      _addPoint(_tempSocHistory, state.temperatureSoc);
      _addPoint(_tempCpuHistory, state.temperatureCpu);
      _addPoint(_tempGpuHistory, state.temperatureGpu);
    });
  }

  void _addPoint(List<double> list, double value) {
    list.add(value);
    if (list.length > _maxPoints) list.removeAt(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
            Text(widget.device.deviceName,
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
                Text('5초 갱신', style: TextStyle(color: AppColors.brandingBlue, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: _latest == null
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.brandingBlue),
                SizedBox(height: 16),
                Text('장비 상태를 불러오는 중...', style: TextStyle(color: AppColors.lightGrey)),
              ],
            ))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── 현재값 요약 칩 ──────────────────────────────
                _buildCurrentValueRow(),
                const SizedBox(height: 20),

                // ── 그래프 6개 ───────────────────────────────────
                _buildChartCard('CPU 사용률', _cpuHistory, Colors.green, '%', 100),
                _buildChartCard('GPU 사용률', _gpuHistory, Colors.deepPurple, '%', 100),
                _buildChartCard('RAM 사용률', _ramHistory, Colors.teal, '%', 100),
                _buildChartCard('SoC 온도', _tempSocHistory, Colors.orange, '℃', 100),
                _buildChartCard('CPU 온도', _tempCpuHistory, Colors.orangeAccent, '℃', 100),
                _buildChartCard('GPU 온도', _tempGpuHistory, Colors.red, '℃', 100),

                // ── 추가 정보 (FPS, 모델, 카메라, 센서) ──────────
                const SizedBox(height: 4),
                _buildExtraInfoCard(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // 현재 값 요약 칩 2열 그리드
  Widget _buildCurrentValueRow() {
    final s = _latest!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('CPU 사용률', '${s.cpuUsage.toStringAsFixed(0)}%', Colors.green),
        _chip('GPU 사용률', '${s.gpuUsage.toStringAsFixed(0)}%', Colors.deepPurple),
        _chip('RAM 사용률', '${s.ramUsage.toStringAsFixed(0)}%', Colors.teal),
        _chip('SoC 온도', '${s.temperatureSoc.toStringAsFixed(0)}℃', Colors.orange),
        _chip('CPU 온도', '${s.temperatureCpu.toStringAsFixed(0)}℃', Colors.orangeAccent),
        _chip('GPU 온도', '${s.temperatureGpu.toStringAsFixed(0)}℃', Colors.red),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label  ', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // 실시간 라인 차트 카드
  Widget _buildChartCard(String title, List<double> data, Color color, String unit, double maxY) {
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
              if (data.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data.last.toStringAsFixed(1)}$unit',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: data.length < 2
                ? const Center(
                    child: Text('데이터 수집 중...', style: TextStyle(color: AppColors.lightGrey, fontSize: 12)),
                  )
                : LineChart(
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
  Widget _buildExtraInfoCard() {
    final s = _latest!;
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
