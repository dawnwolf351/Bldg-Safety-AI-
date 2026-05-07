import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';
import 'device_management_view.dart';
import 'settings_view.dart';
import 'inspection_history_view.dart';
import 'field_monitoring_view.dart';
import 'structure_management_view.dart';
import '../services/report_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0; // 하단 네비게이션 바 상태 관리
  int _selectedDeviceIndex = 0; // 현재 선택된 장치 인덱스
  
  // ★ [캐싱] VideoStreamWidget 재생성 방지
  // Consumer 리빌드 시 동일 장치면 기존 위젯을 재사용하여 RTSP 재연결 방지
  int? _cachedDeviceId;
  Widget? _cachedVideoWidget;

  @override
  void initState() {
    super.initState();
    // [로직 보존]: 화면이 로드되면 데이터 패치 시작 (기존 로직 유지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchDashboardData();
      // 장치 목록도 함께 불러오기
      Provider.of<DeviceViewModel>(context, listen: false).fetchDevices();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 4) {
      // 5번째 탭(인덱스 4)은 로그아웃 역할
      Provider.of<AuthViewModel>(context, listen: false).logout();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 테마 컬러 정의 (시안 1, 2의 하이테크 레이아웃)
    const Color navyBase = Color(0xFF0F172A);
    const Color navyCard = Color(0xFF1E293B);
    const Color cyanAccent = Color(0xFF00E5FF);
    const Color redEmergency = Color(0xFFFF3B30);

    // 장치 관리 뷰를 복구한 4+1(로그아웃) 체계
    final List<Widget> pages = [
      _buildMainDashboardBody(navyCard, cyanAccent, redEmergency),
      const InspectionHistoryView(), // 진단 내역 화면
      const DeviceManagementView(),  // 장치 관리 화면 (드론 용어 제외)
      const SettingsView(),
      const SizedBox.shrink(), // 로그아웃 임시용
    ];

    return Scaffold(
      backgroundColor: navyBase,
      body: pages[_currentIndex],
      // 하단 네비게이션 바 (로그아웃 포함 4개 탭)
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: navyBase,
          selectedItemColor: cyanAccent,
          unselectedItemColor: Colors.grey[500],
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onBottomNavTapped,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: '대시보드'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: '진단 내역'),
            BottomNavigationBarItem(icon: Icon(Icons.sensors_outlined), activeIcon: Icon(Icons.sensors), label: '장치 관리'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '설정'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: '로그아웃'), // 누르면 곧바로 로그아웃 처리
          ],
        ),
      ),
    );
  }

  // 기존 메인 대시보드 전용 본문(인덱스 0)
  Widget _buildMainDashboardBody(Color navyCard, Color cyanAccent, Color redEmergency) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(cyanAccent),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('실시간 현장 영상', 'REAL-TIME CAMERA FEED', cyanAccent),
                  const SizedBox(height: 12),
                  _buildVideoFeedSection(cyanAccent, redEmergency),
                  const SizedBox(height: 28),
                  _buildSectionTitle('AI 추론 인프라 가동 상태', 'INFERENCE MODULE STATUS', cyanAccent),
                  const SizedBox(height: 12),
                  _buildInferenceStatusGrid(navyCard, cyanAccent, redEmergency),
                  const SizedBox(height: 28),
                  _buildSectionTitle('격자형 퀵 액션', 'QUICK ACTIONS', cyanAccent),
                  const SizedBox(height: 12),
                  _buildActionGridButtons(navyCard, cyanAccent, redEmergency),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 헤더 위젯
  Widget _buildHeader(Color cyanAccent) {
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
                  color: cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.memory, color: cyanAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VISION AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('STRUCTURAL DIAGNOSIS', style: TextStyle(color: cyanAccent.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cyanAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: cyanAccent, size: 16),
                const SizedBox(width: 6),
                const Text('AI Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 섹션 타이틀 공통 위젯
  Widget _buildSectionTitle(String title, String subtitle, Color cyanAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: cyanAccent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  // 실시간 영상 및 AI 분석 영역 — 등록된 장치 목록과 연동
  Widget _buildVideoFeedSection(Color cyanAccent, Color redEmergency) {
    return Consumer<DeviceViewModel>(
      builder: (context, deviceVM, child) {
        final devices = deviceVM.devices;

        // 장치가 없는 경우 안내 UI
        if (devices.isEmpty) {
          _cachedDeviceId = null;
          _cachedVideoWidget = null;
          return _buildNoDeviceVideoPlaceholder(cyanAccent);
        }

        // 인덱스 범위 보정
        if (_selectedDeviceIndex >= devices.length) {
          _selectedDeviceIndex = 0;
        }
        final selectedDevice = devices[_selectedDeviceIndex];

        return Column(
          children: [
            // [1] 장치 선택 탭 (수평 스크롤)
            _buildDeviceSelector(devices, cyanAccent),
            const SizedBox(height: 12),
            // [2] 선택된 장치의 영상 피드 영역
            // ★ 동일 장치면 캐시된 영상 위젯을 재사용 (RTSP 재연결 방지)
            _buildDeviceVideoFeedCached(selectedDevice, cyanAccent, redEmergency),
          ],
        );
      },
    );
  }

  // ★ [핵심] 장치가 변경되지 않으면 기존 영상 위젯을 그대로 리턴
  // DeviceViewModel 폴링으로 Consumer가 리빌드되어도 영상이 끄기지 않음
  Widget _buildDeviceVideoFeedCached(Device device, Color cyanAccent, Color redEmergency) {
    // 장치가 바뀌었을 때만 새 영상 위젯 생성
    if (_cachedDeviceId != device.id) {
      _cachedDeviceId = device.id;
      _cachedVideoWidget = _buildDeviceVideoFeed(device, cyanAccent, redEmergency);
    }
    return _cachedVideoWidget!;
  }

  // 장치 선택 수평 스크롤 탭
  Widget _buildDeviceSelector(List<Device> devices, Color cyanAccent) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final isSelected = _selectedDeviceIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDeviceIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? cyanAccent.withValues(alpha: 0.15) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? cyanAccent : const Color(0xFF334155),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? const Color(0xFF22C55E) : Colors.grey[600],
                      boxShadow: device.isOnline
                          ? [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.deviceName,
                    style: TextStyle(
                      color: isSelected ? cyanAccent : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 선택된 장치의 영상 피드 (추후 실시간 영상으로 교체)
  Widget _buildDeviceVideoFeed(Device device, Color cyanAccent, Color redEmergency) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          // 장치가 온라인이면 실시간 RTSP 스트리밍 표시, 오프라인이면 안내 메시지
          if (device.isOnline)
            Positioned.fill(
              child: VideoStreamWidget(
                // ★ ValueKey로 장치 전환 시 위젯 강제 재생성 (기존 스트림 해제 → 새 스트림 연결)
                key: ValueKey('video_${device.id}'),
                // 하드코딩된 테스트 URL (추후 device.lastKnownIp 등으로 동적 할당 가능)
                rtspUrl: 'rtsp://100.84.57.123:8554/ds-test',
                // 전체화면 진입 콜백 — VideoController를 넘겨받아 FullscreenVideoPage에 전달
                onFullscreen: (videoController) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullscreenVideoPage(
                        videoController: videoController,
                        deviceName: device.deviceName,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off_rounded,
                    color: Colors.grey[700],
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '장치가 오프라인 상태입니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI 영상 분석 모듈 연동 준비 중',
                    style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  ),
                ],
              ),
            ),
          // 좌측 상단 — 장치명 + LIVE 표시
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: device.isOnline ? Colors.redAccent : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.isOnline ? 'LIVE' : 'OFFLINE',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
          ),
          // 우측 상단 — 전체화면 버튼 + 장치 상태 아이콘
          Positioned(
            top: 12, right: 12,
            child: Row(
              children: [
                // 전체화면 버튼은 VideoStreamWidget 내부에서 직접 처리됨
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.memory, color: cyanAccent.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 6),
                      Icon(Icons.wifi, color: device.isOnline ? Colors.white : Colors.grey[700], size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단 — 장치 정보 바
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[400], size: 12),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${device.location}  •  MAC: ${device.macAddress}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.isOnline ? cyanAccent.withValues(alpha: 0.15) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: device.isOnline ? cyanAccent.withValues(alpha: 0.5) : Colors.grey[700]!,
                      ),
                    ),
                    child: Text(
                      device.isOnline ? 'AI 분석 대기' : '연결 끊김',
                      style: TextStyle(
                        color: device.isOnline ? cyanAccent : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  // 등록된 장치가 없을 때 보여주는 안내 UI
  Widget _buildNoDeviceVideoPlaceholder(Color cyanAccent) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, color: Colors.grey[700], size: 48),
            const SizedBox(height: 16),
            Text(
              '등록된 장치가 없습니다',
              style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '장치 관리 메뉴에서 AI 단말을 등록해주세요',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _currentIndex = 2; // 장치 관리 탭으로 이동
                });
              },
              icon: Icon(Icons.add_circle_outline, color: cyanAccent, size: 16),
              label: Text('장치 등록하러 가기', style: TextStyle(color: cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cyanAccent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI 서버 상태 4-그리드 카드 영역
  Widget _buildInferenceStatusGrid(Color cardColor, Color cyanAccent, Color redEmergency) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _buildStatCard(cardColor, Icons.memory, cyanAccent, 'Online', 'Module Status', '서버 가동 상태', true),
        _buildStatCard(cardColor, Icons.track_changes, cyanAccent, '98.5%', 'Detection Accuracy', '평균 탐지 정확도', true),
        _buildStatCard(cardColor, Icons.developer_board, const Color(0xFFFFB020), '78%', 'GPU Usage', 'GPU 리소스', false),
        _buildStatCard(cardColor, Icons.queue_play_next, cyanAccent, '4', 'Pending Queue', '대기 중인 작업', true),
      ],
    );
  }

  // 개별 통계 카드 위젯 생성기
  Widget _buildStatCard(Color cardColor, IconData icon, Color primaryColor, String value, String titleEn, String titleKo, bool isUpTrend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: primaryColor, size: 22),
              // Trend 상태 대신 Online 마커 용도
              Icon(isUpTrend ? Icons.circle : Icons.warning_amber_rounded, color: isUpTrend ? primaryColor : Colors.orangeAccent, size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 2),
          Flexible(child: Text(titleEn, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Flexible(child: Text(titleKo, style: TextStyle(color: Colors.grey[400], fontSize: 9), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // 격자형 버튼 영역 (하단 4버튼)
  Widget _buildActionGridButtons(Color cardColor, Color cyanAccent, Color redEmergency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(cardColor, Icons.monitor, '현장 모니터링', cyanAccent, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldMonitoringView()));
        }),
        _buildActionButton(cardColor, Icons.architecture, '구조물 관리', cyanAccent, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StructureManagementView()));
        }),
        // 보고서 생성 (PDF)
        _buildActionButton(cardColor, Icons.picture_as_pdf_outlined, '보고서 생성', cyanAccent, onTap: () {
          _showReportDeviceSelector(context, cyanAccent);
        }),
        // 119 긴급 신고 (강렬한 빨간색 및 사이렌)
        _buildActionButton(cardColor, Icons.campaign, '119 긴급 신고', redEmergency, isEmergency: true),
      ],
    );
  }

  // 액션 버튼 아이템 위젯
  Widget _buildActionButton(Color cardColor, IconData icon, String label, Color iconColor, {bool isEmergency = false, VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label 실행 중...')));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEmergency ? Colors.redAccent.withValues(alpha: 0.6) : Colors.blueGrey.withValues(alpha: 0.2),
                  width: isEmergency ? 1.5 : 1.0,
                ),
                boxShadow: isEmergency ? [
                  BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 10)
                ] : null,
              ),
              child: Column(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: isEmergency ? Colors.red[200] : Colors.grey[300],
                      fontSize: 11,
                      fontWeight: isEmergency ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 보고서 생성 시 장치 선택 모달
  void _showReportDeviceSelector(BuildContext context, Color cyanAccent) {
    final devices = Provider.of<DeviceViewModel>(context, listen: false).devices;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('등록된 장치가 없습니다. 장치 관리에서 먼저 등록해주세요.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 선택 상태 관리 (기본: 전체 선택)
    final selectedMap = <int, bool>{};
    for (final device in devices) {
      selectedMap[device.id] = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCount = selectedMap.values.where((v) => v).length;
            final allSelected = selectedCount == devices.length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 핸들
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 타이틀
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('보고서 생성 대상 선택', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$selectedCount개 장치 선택됨', style: TextStyle(color: cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      // 전체 선택/해제 토글
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            final newValue = !allSelected;
                            for (final device in devices) {
                              selectedMap[device.id] = newValue;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cyanAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            allSelected ? '전체 해제' : '전체 선택',
                            style: TextStyle(color: cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 장치 리스트
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected = selectedMap[device.id] ?? false;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedMap[device.id] = !isSelected;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? cyanAccent.withValues(alpha: 0.08) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? cyanAccent.withValues(alpha: 0.5) : const Color(0xFF334155),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 체크박스
                                Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? cyanAccent : Colors.transparent,
                                    border: Border.all(color: isSelected ? cyanAccent : Colors.grey[600]!, width: 2),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Color(0xFF0F172A), size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                // 장치 상태 표시등
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: device.isOnline ? const Color(0xFF22C55E) : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // 장치 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(device.deviceName, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, color: Colors.grey[600], size: 11),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              '${device.location}  •  ${device.macAddress}',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 보고서 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: selectedCount == 0
                          ? null
                          : () {
                              final selectedDevices = devices.where((d) => selectedMap[d.id] == true).toList();
                              Navigator.pop(context); // 모달 닫기
                              ReportService.generateAndPreview(context, selectedDevices);
                            },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text('$selectedCount개 장치 보고서 생성', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyanAccent,
                        foregroundColor: const Color(0xFF0F172A),
                        disabledBackgroundColor: Colors.grey[800],
                        disabledForegroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// [RTSP 스트리밍 전용 위젯]
// 젯슨 나노 딥스트림 영상을 Tailscale 환경에서 안정적으로 수신하기 위한 media_kit 플레이어
// flutter_vlc_player → media_kit 전환 (MobileVLCKit이 iOS 26 미지원)
// [구현 사항]
//   1. dispose() 비동기 처리 → 크래시 방지
//   2. didUpdateWidget() → URL 변경 시 플레이어 재초기화
//   3. ValueKey 기반 강제 재생성 지원 (호출부에서 key 전달)
//   4. 에러 상태 핸들링 → 무한 로딩 방지 + 재연결 버튼
// -----------------------------------------------------------------------------
class VideoStreamWidget extends StatefulWidget {
  final String rtspUrl;
  final void Function(VideoController controller)? onFullscreen;

  const VideoStreamWidget({super.key, required this.rtspUrl, this.onFullscreen});

  @override
  State<VideoStreamWidget> createState() => _VideoStreamWidgetState();
}

class _VideoStreamWidgetState extends State<VideoStreamWidget> {
  Player? _player;
  VideoController? _videoController;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDisposing = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // ★ URL이 변경되면(다른 장치 선택 시) 플레이어를 재초기화
  @override
  void didUpdateWidget(VideoStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rtspUrl != widget.rtspUrl) {
      _disposePlayer().then((_) {
        if (mounted) {
          _initializePlayer();
        }
      });
    }
  }

  void _initializePlayer() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isPlaying = false;
    });

    debugPrint('🎥 [영상 연결 시도] URL: ${widget.rtspUrl}');

    try {
      // media_kit Player 생성
      final player = Player();

      // ★ RTSP TCP 강제 설정 (iOS에서 UDP 차단 대응)
      // media_kit은 libmpv 기반이므로 mpv 속성명을 사용해야 함
      try {
        final nativePlayer = player.platform as dynamic;
        // ffmpeg/lavf 옵션으로 RTSP TCP 전송 강제
        await nativePlayer.setProperty('demuxer-lavf-o', 'rtsp_transport=tcp');
        debugPrint('✅ [mpv] RTSP TCP 모드 설정 완료');
      } catch (e) {
        debugPrint('⚠️ [mpv] 속성 설정 실패 (계속 진행): $e');
      }

      // 비디오 컨트롤러 생성
      final videoController = VideoController(player);

      // ────────────────────────────────────
      // 디버그용 스트림 구독 (모든 상태 변화 추적)
      // ────────────────────────────────────
      
      // 에러 스트림
      player.stream.error.listen((error) {
        debugPrint('🚨 [Player 에러] $error');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error;
          });
        }
      });

      // 재생 상태 스트림
      player.stream.playing.listen((playing) {
        debugPrint('▶️ [Player playing] $playing');
        if (mounted && playing && !_isPlaying) {
          setState(() => _isPlaying = true);
        }
      });

      // 버퍼링 상태 스트림
      player.stream.buffering.listen((buffering) {
        debugPrint('⏳ [Player buffering] $buffering');
      });

      // 영상 크기 스트림 — 프레임이 실제로 도착했는지 확인하는 가장 확실한 지표
      player.stream.width.listen((width) {
        debugPrint('📐 [Player width] $width');
        if (mounted && width != null && width > 0 && !_isPlaying) {
          debugPrint('✅ [영상 수신 확인!] 프레임 도착 — 로딩 해제');
          setState(() => _isPlaying = true);
        }
      });

      // 로그 스트림 (mpv 내부 로그)
      player.stream.log.listen((log) {
        debugPrint('📋 [mpv ${log.level}] ${log.text}');
      });

      // RTSP 스트림 열기
      debugPrint('🔗 [Player.open] RTSP 스트림 열기 시작...');
      await player.open(Media(widget.rtspUrl));
      debugPrint('🔗 [Player.open] 호출 완료 (연결 대기 중...)');

      if (mounted) {
        setState(() {
          _player = player;
          _videoController = videoController;
        });
      }

      // ★ 15초 타임아웃 — 연결 실패 시 무한 로딩 방지
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && !_isPlaying && !_hasError) {
          debugPrint('⏰ [타임아웃] 15초 경과 — 영상 미수신. 에러 표시');
          setState(() {
            _hasError = true;
            _errorMessage = 'RTSP 서버 응답 없음 (15초 타임아웃)\n'
                '• Tailscale 연결 상태를 확인하세요\n'
                '• Jetson Nano에서 DeepStream이 실행 중인지 확인하세요';
          });
        }
      });
    } catch (e) {
      debugPrint('🚨 media_kit 플레이어 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '플레이어 초기화 실패: $e';
        });
      }
    }
  }

  // 비동기 dispose → 크래시 방지
  Future<void> _disposePlayer() async {
    if (_isDisposing) return;
    _isDisposing = true;

    try {
      final player = _player;
      _player = null;
      _videoController = null;

      if (player != null) {
        await player.dispose();
      }
    } catch (e) {
      debugPrint('⚠️ media_kit 플레이어 dispose 중 에러 (무시): $e');
    } finally {
      _isDisposing = false;
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 에러 상태 UI
    if (_hasError) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFF0A0F1A),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
                const SizedBox(height: 12),
                const Text(
                  '스트리밍 연결 실패',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _disposePlayer().then((_) {
                      if (mounted) _initializePlayer();
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF), size: 16),
                  label: const Text('재연결', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 컨트롤러 초기화 대기 중
    if (_videoController == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFF0A0F1A),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00E5FF)),
                SizedBox(height: 12),
                Text('플레이어 초기화 중...', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    // media_kit Video 위젯으로 스트리밍 렌더링
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Video(controller: _videoController!),
          // 영상이 아직 재생되지 않을 때 로딩 오버레이 표시
          if (!_isPlaying)
            Container(
              color: const Color(0xFF0A0F1A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    SizedBox(height: 12),
                    Text('스트리밍 연결 중...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          // ★ 전체화면 버튼 (영상 재생 중일 때만 표시, 하단 장치 정보 바 위쪽)
          if (_isPlaying && widget.onFullscreen != null)
            Positioned(
              bottom: 50, right: 10,
              child: GestureDetector(
                onTap: () => widget.onFullscreen!(_videoController!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// [전체화면 영상 뷰]
// 대시보드의 기존 VideoController를 그대로 받아서 전체화면으로 표시합니다.
// 새 Player를 생성하지 않으므로 RTSP 재연결 없이 즉시 전체화면 전환됩니다.
// 진입 시 가로 고정 → 뒤로가기 시 세로 모드 복원
// -----------------------------------------------------------------------------
class FullscreenVideoPage extends StatefulWidget {
  final VideoController videoController;
  final String deviceName;

  const FullscreenVideoPage({
    super.key,
    required this.videoController,
    required this.deviceName,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // 가로 모드 고정 + 시스템 UI 숨기기 (몰입형 전체화면)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    // 세로 모드 복원 + 시스템 UI 표시
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // 비정상 종료 대비 세로 모드 복원
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // ★ Player를 dispose하지 않음 — 대시보드로 돌아갔을 때 계속 재생해야 하므로
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // 기존 VideoController를 전체화면으로 표시 (재연결 없음)
            Positioned.fill(
              child: Video(
                controller: widget.videoController,
                fill: Colors.black,
              ),
            ),

            // 컨트롤 오버레이 (탭으로 토글)
            if (_showControls) ...[
              // 상단 그라데이션 바
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 장치명 + LIVE 배지
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(width: 16),
                            Text(widget.deviceName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        // 전체화면 나가기 버튼
                        GestureDetector(
                          onTap: _exitFullscreen,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
