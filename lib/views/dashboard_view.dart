import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'device_management_view.dart';
import 'settings_view.dart';
import 'inspection_history_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0; // 하단 네비게이션 바 상태 관리

  @override
  void initState() {
    super.initState();
    // [로직 보존]: 화면이 로드되면 데이터 패치 시작 (기존 로직 유지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchDashboardData();
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

  // 실시간 영상 및 AI 경계 상자 렌더링 영역 (Mock UI)
  Widget _buildVideoFeedSection(Color cyanAccent, Color redEmergency) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
        image: const DecorationImage(
          // 멋진 구조물/교량 Mock 이미지 (기존 Unsplash 404 에러로 인한 Picsum 대체)
          image: NetworkImage('https://picsum.photos/seed/drone/1000/800'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // 영상 필터 (어둡게 처리)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // 좌측 상단 REC / LIVE 표시
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('LIVE | HD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
          // 우측 상단 단말 연결 상태
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.battery_4_bar, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Icon(Icons.wifi, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
          // AI 진단 빨간색 Bounding Box (화재 감지 연출)
          Positioned(
            top: 70, left: 120,
            width: 140, height: 100,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: redEmergency, width: 2.5),
                color: redEmergency.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Bounding Box 위 텍스트 라벨
          Positioned(
            top: 45, left: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: redEmergency,
              child: const Text('화재 감지 (98%)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          // 하단 위험 경고 바
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: redEmergency, size: 18),
                  const SizedBox(width: 8),
                  Text('위험: 화재 발생 중 (긴급 조치 요망)', style: TextStyle(color: redEmergency, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
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
        _buildActionButton(cardColor, Icons.monitor, '현장 모니터링', cyanAccent),
        _buildActionButton(cardColor, Icons.architecture, '구조물 관리', cyanAccent),
        // 보고서 생성 (PDF 아이콘)
        _buildActionButton(cardColor, Icons.picture_as_pdf_outlined, '보고서 생성', cyanAccent),
        // 119 긴급 신고 (강렬한 빨간색 및 사이렌)
        _buildActionButton(cardColor, Icons.campaign, '119 긴급 신고', redEmergency, isEmergency: true),
      ],
    );
  }

  // 액션 버튼 아이템 위젯
  Widget _buildActionButton(Color cardColor, IconData icon, String label, Color iconColor, {bool isEmergency = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Action logic mock
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
}

