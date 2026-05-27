import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';
import '../theme/app_colors.dart';
import 'device_management_view.dart';
import 'settings_view.dart';
import 'inspection_history_view.dart';
import 'field_monitoring_view.dart';
import 'structure_management_view.dart';
import '../services/report_service.dart';
import '../models/device_state.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'safety_grade_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0; // 하단 네비게이션 바 상태 관리
  int _selectedDeviceIndex = 0; // 현재 선택된 장치 인덱스
  
  // ★ [캐싱] VideoStreamWidget 재생성 방지
  int? _cachedDeviceId;
  bool? _cachedDeviceOnlineStatus;
  Widget? _cachedVideoWidget;

  // ─── 색상 토큰: AppColors 참조 ──────────────────────────
  static const Color bgOffWhite   = AppColors.bgOffWhite;
  static const Color cardWhite    = AppColors.cardWhite;
  static const Color textCharcoal = AppColors.charcoal;
  static const Color textLightGrey = AppColors.lightGrey;
  static const Color brandingBlue = AppColors.brandingBlue;
  static const Color borderLight  = AppColors.borderLight;

  @override
  void initState() {
    super.initState();
    // [로직 보존]: 화면이 로드되면 데이터 패치 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchDashboardData();
      final deviceVM = Provider.of<DeviceViewModel>(context, listen: false);
      deviceVM.fetchDevices().then((_) {
        if (!mounted) return;
        // 기기 목록 로드 후 첫 번째 기기의 상태 정보 조회
        if (deviceVM.devices.isNotEmpty) {
          Provider.of<DashboardViewModel>(context, listen: false)
            .fetchDeviceState(deviceVM.devices.first.id);
        }
      });
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 4) {
      // 5번째 탭(인덱스 4)은 로그아웃 역할 - 확인 팝업 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: cardWhite,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold, color: textCharcoal)),
          content: const Text('정말 로그아웃 하시겠습니까?', style: TextStyle(color: textLightGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('아니오', style: TextStyle(color: textLightGrey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<AuthViewModel>(context, listen: false).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandingBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('예', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 장치 관리 뷰를 포함한 4+1(로그아웃) 체계 유지
    final List<Widget> pages = [
      _buildMobileAdminDashboardBody(),
      const InspectionHistoryView(), // 진단 내역 화면
      const DeviceManagementView(),  // 장치 관리 화면
      const SettingsView(),          // 설정 화면
      const SizedBox.shrink(),       // 로그아웃 (이동 방지용)
    ];

    return Scaffold(
      backgroundColor: bgOffWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      // 하단 네비게이션 바 (모바일 UI)
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: BottomNavigationBar(
            backgroundColor: cardWhite,
            selectedItemColor: brandingBlue,
            unselectedItemColor: textLightGrey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: '대시보드'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: '진단 내역'),
              BottomNavigationBarItem(icon: Icon(Icons.sensors_outlined), activeIcon: Icon(Icons.sensors), label: '장치 관리'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '설정'),
              BottomNavigationBarItem(icon: Icon(Icons.logout), label: '로그아웃'),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 메인 대시보드 본문 (Mobile White Admin Layout)
  // =========================================================================
  Widget _buildMobileAdminDashboardBody() {
    return SafeArea(
      child: Column(
        children: [
          // 모바일용 간결한 헤더
          _buildMobileHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Main Video Feed (제일 상단)
                  _buildMainVideoCard(),
                  const SizedBox(height: 24),
                  
                  // 2. Summary Cards (영상 밑으로 배치, 타이틀 추가)
                  const Text('AI 추론 인프라 가동상태', style: TextStyle(color: textCharcoal, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSummaryCardsGrid(),
                  const SizedBox(height: 24),
                  
                  // 3. Quick Actions
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 모바일용 상단 헤더 (로고)
  Widget _buildMobileHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: brandingBlue, size: 28),
              SizedBox(width: 8),
              Text(
                'SOC 진단 시스템',
                style: TextStyle(color: textCharcoal, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4개의 통계 카드 영역 (모바일용 가로 배치 - 퀵 액션 크기)
  Widget _buildSummaryCardsGrid() {
    return Consumer2<DeviceViewModel, DashboardViewModel>(
      builder: (context, deviceVM, dashVM, child) {
        final devices = deviceVM.devices;
        final onlineCount = devices.where((d) => d.isOnline).length;
        final defectCount = dashVM.defects.length;

        // 선택된 기기의 상태 정보
        DeviceState? selectedState;
        if (devices.isNotEmpty && _selectedDeviceIndex < devices.length) {
          selectedState = dashVM.deviceStates[devices[_selectedDeviceIndex].id];
        }

        final cpuText = selectedState != null ? '${selectedState.cpuUsage.toStringAsFixed(0)}%' : '--';
        final tempText = selectedState != null ? '${selectedState.maxTemperature.toStringAsFixed(0)}℃' : '--';
        final cpuStatus = selectedState != null ? (selectedState.cpuUsage < 70 ? '안정적' : '부하 주의') : '조회 중';
        final tempStatus = selectedState != null ? (selectedState.isOverheated ? '과열 경고!' : '정상 범위') : '조회 중';

        return Row(
          children: [
            Expanded(child: _buildAdminStatCard('전체 장치', '${devices.length}', Icons.dns_outlined, brandingBlue, '$onlineCount대 온라인', true)),
            const SizedBox(width: 8),
            Expanded(child: _buildAdminStatCard('발견 결함', '$defectCount', Icons.warning_amber_rounded, Colors.redAccent, defectCount > 0 ? '확인 필요' : '이상 없음', defectCount == 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildAdminStatCard('CPU 사용률', cpuText, Icons.memory, Colors.green, cpuStatus, selectedState == null || selectedState.cpuUsage < 70)),
            const SizedBox(width: 8),
            Expanded(child: _buildAdminStatCard('기기 온도', tempText, Icons.thermostat, Colors.orangeAccent, tempStatus, selectedState == null || !selectedState.isOverheated)),
          ],
        );
      },
    );
  }

  Widget _buildAdminStatCard(String title, String value, IconData icon, Color iconColor, String statusText, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: textLightGrey, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPositive ? Icons.check_circle_outline : Icons.trending_up, color: isPositive ? Colors.green : Colors.redAccent, size: 8),
              const SizedBox(width: 2),
              Flexible(child: Text(statusText, style: TextStyle(color: isPositive ? Colors.green : Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1)),
            ],
          ),
        ],
      ),
    );
  }

  // 실시간 영상 피드 메인 카드
  Widget _buildMainVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<DeviceViewModel>(
              builder: (context, deviceVM, child) {
                final devices = deviceVM.devices;
                final bool isOnline = (devices.isNotEmpty && _selectedDeviceIndex < devices.length) 
                    ? devices[_selectedDeviceIndex].isOnline 
                    : false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('실시간 현장 영상 피드', style: TextStyle(color: textCharcoal, fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOnline ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: isOnline ? Colors.green : Colors.grey, size: 8),
                          const SizedBox(width: 4),
                          Text(isOnline ? 'Live' : 'Offline', style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer<DeviceViewModel>(
              builder: (context, deviceVM, child) {
                final devices = deviceVM.devices;
                if (devices.isEmpty) {
                  _cachedDeviceId = null;
                  _cachedDeviceOnlineStatus = null;
                  _cachedVideoWidget = null;
                  return _buildNoDeviceVideoPlaceholder();
                }

                if (_selectedDeviceIndex >= devices.length) {
                  _selectedDeviceIndex = 0;
                }
                final selectedDevice = devices[_selectedDeviceIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 장치 선택 탭
                    _buildDeviceSelectorTokens(devices),
                    const SizedBox(height: 12),
                    // 캐시된 비디오 위젯
                    _buildDeviceVideoFeedCached(selectedDevice),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 화이트 테마용 장치 선택 탭 (Chips 형태)
  Widget _buildDeviceSelectorTokens(List<Device> devices) {
    return SizedBox(
      height: 36,
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
              // 선택된 기기의 상태 정보 비동기 로드
              Provider.of<DashboardViewModel>(context, listen: false)
                .fetchDeviceState(device.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? brandingBlue : bgOffWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected ? brandingBlue : borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? Colors.greenAccent : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    device.deviceName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textCharcoal,
                      fontSize: 12,
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

  Widget _buildDeviceVideoFeedCached(Device device) {
    if (_cachedDeviceId != device.id || _cachedDeviceOnlineStatus != device.isOnline) {
      _cachedDeviceId = device.id;
      _cachedDeviceOnlineStatus = device.isOnline;
      _cachedVideoWidget = _buildDeviceVideoFeed(device);
    }
    return _cachedVideoWidget!;
  }

  Widget _buildDeviceVideoFeed(Device device) {
    return Container(
      width: double.infinity,
      height: 240, // 모바일 최적화 높이
      decoration: BoxDecoration(
        color: Colors.black, // 영상 배경은 몰입감을 위해 블랙 유지
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
      ),
      child: Stack(
        children: [
          if (device.isOnline)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoStreamWidget(
                  key: ValueKey('video_${device.id}'),
                  rtspUrl: 'rtsp://121.144.41.106:6380/live',
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
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.grey[600], size: 48),
                  const SizedBox(height: 12),
                  const Text('장치가 오프라인 상태입니다', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
          // 화이트 테마에 맞춘 모바일 영상 정보 오버레이
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${device.location}  •  ${device.macAddress}', style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                  ),
                  // AI 분석 상태 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.isOnline ? brandingBlue : Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      device.isOnline ? 'AI Active' : 'Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoDeviceVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: bgOffWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors_off, color: textLightGrey, size: 48),
            const SizedBox(height: 12),
            const Text('등록된 장치가 없습니다', style: TextStyle(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('장치 관리에서 AI 단말을 등록해주세요', style: TextStyle(color: textLightGrey, fontSize: 11)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _onBottomNavTapped(2),
              icon: const Icon(Icons.add_circle_outline, color: brandingBlue, size: 16),
              label: const Text('장치 등록하러 가기', style: TextStyle(color: brandingBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: brandingBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 퀵 액션 (모바일 최적화 작게, 가로 배열)
  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('퀵 액션', style: TextStyle(color: textCharcoal, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionGridButton(Icons.monitor, '현장\n모니터링', brandingBlue, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldMonitoringView()));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionGridButton(Icons.architecture, '구조물\n관리', brandingBlue, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StructureManagementView()));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionGridButton(Icons.picture_as_pdf_outlined, '보고서\n생성', brandingBlue, onTap: () {
                _showReportDeviceSelector(context);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionGridButton(Icons.shield_outlined, '안전등급\n기준표', brandingBlue, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyGradeView()));
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGridButton(IconData icon, String title, Color iconColor, {bool isEmergency = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isEmergency ? Colors.redAccent.withValues(alpha: 0.1) : cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEmergency ? Colors.redAccent.withValues(alpha: 0.3) : borderLight),
          boxShadow: isEmergency ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: isEmergency ? Colors.redAccent : textCharcoal, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  // 보고서 생성 시 장치 선택 모달 (화이트 테마 & 모바일 사이즈 최적화)
  void _showReportDeviceSelector(BuildContext context) {
    final devices = Provider.of<DeviceViewModel>(context, listen: false).devices;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록된 장치가 없습니다.'), backgroundColor: Colors.red));
      return;
    }

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
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: borderLight, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('보고서 대상 선택', style: TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            final newValue = !allSelected;
                            for (final device in devices) {
                              selectedMap[device.id] = newValue;
                            }
                          });
                        },
                        child: Text(allSelected ? '전체 해제' : '전체 선택', style: const TextStyle(color: brandingBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected = selectedMap[device.id] ?? false;
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isSelected,
                          activeColor: brandingBlue,
                          title: Text(device.deviceName, style: const TextStyle(fontWeight: FontWeight.bold, color: textCharcoal, fontSize: 14)),
                          subtitle: Text(device.isOnline ? 'Online' : 'Offline', style: TextStyle(color: device.isOnline ? Colors.green : textLightGrey, fontSize: 11)),
                          onChanged: (val) => setModalState(() => selectedMap[device.id] = val ?? false),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: selectedCount == 0
                          ? null
                          : () {
                              final selectedDevices = devices.where((d) => selectedMap[d.id] == true).toList();
                              Navigator.pop(context);
                              ReportService.generateAndPreview(context, selectedDevices);
                            },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: Text('$selectedCount개 장치 보고서 생성', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandingBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// =========================================================================
// [RTSP 스트리밍 전용 위젯] 기존 로직 완전히 동일하게 보존
// =========================================================================
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

  @override
  void didUpdateWidget(VideoStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rtspUrl != widget.rtspUrl) {
      _disposePlayer().then((_) {
        if (mounted) _initializePlayer();
      });
    }
  }

  void _initializePlayer() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isPlaying = false;
    });

    try {
      final player = Player();
      try {
        final nativePlayer = player.platform as dynamic;
        await nativePlayer.setProperty('demuxer-lavf-o', 'rtsp_transport=tcp');
      } catch (e) {
        debugPrint('RTSP TCP 설정 무시됨');
      }

      final videoController = VideoController(player);

      player.stream.error.listen((error) {
        if (mounted) setState(() { _hasError = true; _errorMessage = error; });
      });

      player.stream.playing.listen((playing) {
        if (mounted && playing && !_isPlaying) setState(() => _isPlaying = true);
      });

      player.stream.width.listen((width) {
        if (mounted && width != null && width > 0 && !_isPlaying) setState(() => _isPlaying = true);
      });

      await player.open(Media(widget.rtspUrl));

      if (mounted) {
        setState(() {
          _player = player;
          _videoController = videoController;
        });
      }

      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && !_isPlaying && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = 'RTSP 타임아웃 (네트워크 또는 Jetson 확인 필요)';
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() { _hasError = true; _errorMessage = '초기화 에러: $e'; });
    }
  }

  Future<void> _disposePlayer() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      final player = _player;
      _player = null;
      _videoController = null;
      if (player != null) await player.dispose();
    } catch (e) {
      debugPrint('dispose error: $e');
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
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            const Text('스트리밍 연결 실패', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _disposePlayer().then((_) { if (mounted) _initializePlayer(); }),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('재연결', style: TextStyle(fontSize: 12)),
            )
          ],
        ),
      );
    }

    if (_videoController == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      children: [
        Video(controller: _videoController!),
        if (!_isPlaying)
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_isPlaying && widget.onFullscreen != null)
          Positioned(
            top: 10, right: 10,
            child: GestureDetector(
              onTap: () => widget.onFullscreen!(_videoController!),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}

// =========================================================================
// [전체화면 영상 뷰] 기존 로직 완전히 동일하게 보존
// =========================================================================
class FullscreenVideoPage extends StatefulWidget {
  final VideoController videoController;
  final String deviceName;

  const FullscreenVideoPage({super.key, required this.videoController, required this.deviceName});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
            Positioned.fill(child: Video(controller: widget.videoController, fill: Colors.black)),
            if (_showControls)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent]),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Text('${widget.deviceName} LIVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.fullscreen_exit, color: Colors.white), onPressed: _exitFullscreen),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
