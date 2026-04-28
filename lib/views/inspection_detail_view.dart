import 'package:flutter/material.dart';

class InspectionDetailView extends StatefulWidget {
  final Map<String, dynamic> inspectionData;

  const InspectionDetailView({super.key, required this.inspectionData});

  @override
  State<InspectionDetailView> createState() => _InspectionDetailViewState();
}

class _InspectionDetailViewState extends State<InspectionDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color _navyBase = const Color(0xFF0F172A);
  final Color _navyCard = const Color(0xFF1E293B);
  final Color _cyanAccent = const Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCritical = widget.inspectionData['status'] == 'CRITICAL';
    Color statusColor = isCritical ? const Color(0xFFFF3B30) : (widget.inspectionData['status'] == 'WARNING' ? const Color(0xFFFF9F0A) : const Color(0xFF34C759));

    return Scaffold(
      backgroundColor: _navyBase,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 스크롤 시 앱바 영역으로 접히는 대형 썸네일 (Hero 적용)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _navyBase,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 110), // 뒤로가기 및 원본 보기 버튼 겹침 방지 여백
              title: Text(widget.inspectionData['title'], 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'hero_image_${widget.inspectionData['title']}', // Hero 애니메이션 통일
                    child: Image.network(
                      widget.inspectionData['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.blueGrey[800],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 64),
                      ),
                    ),
                  ),
                  // 어두운 그라데이션 오버레이 (글씨 가독성 및 디자인 향상)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _navyBase.withValues(alpha: 0.9)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // 중앙 둥둥 떠있는 위험 테두리 타겟팅 효과 (CRITICAL 전용)
                  if (isCritical)
                    Center(
                      child: Container(
                        width: 150, height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFF3B30), width: 3),
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  // 우측 하단 영상 재생/확대 뱃지 액션
                  Positioned(
                    bottom: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('원본 보기', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 메인 하단 정보 패널 영역
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 요약 큰 뱃지
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(isCritical ? Icons.warning_rounded : Icons.info_outline, color: statusColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.inspectionData['status'], style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              Text('AI 통합 소견: ${widget.inspectionData['subtitle']} (신뢰도 ${widget.inspectionData['confidence']})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 3종 스펙 정보 탭 바
                  TabBar(
                    controller: _tabController,
                    indicatorColor: _cyanAccent,
                    labelColor: _cyanAccent,
                    unselectedLabelColor: Colors.blueGrey[400],
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: '세부 데이터'),
                      Tab(text: '위치 정보'),
                      Tab(text: '메모'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 스펙 정보 탭 내용 (크기를 잡기 위해 SizedBox로 제한)
                  SizedBox(
                    height: 220,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildDataTab(),
                        _buildLocationTab(),
                        _buildCommentTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // 하단의 버튼들에 의한 가려짐 방지 여백
                ],
              ),
            ),
          )
        ],
      ),
      
      // 하단 고정 액션 바 (바텀 시트 형식)
      bottomSheet: Container(
        color: _navyBase,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보고서 다운로드를 에뮬레이션합니다.')));
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('보고서 (PDF)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cyanAccent,
                  side: BorderSide(color: _cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('조치 완료 또는 상부 보고 처리가 완료되었습니다.')));
                  Navigator.pop(context); // 이전 화면으로 복귀
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(isCritical ? '긴급 출동 요청' : '조치 완료 마킹'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCritical ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* =========== 세부 데이터 탭 모듈 =========== */
  Widget _buildDataTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow('검사 일시', widget.inspectionData['date']),
          _buildDataRow('결함 종류', '콘크리트 미세 균열, 표면 박리'),
          _buildDataRow('결함 크기 추정', '길이 약 12~15cm, 폭 2mm 이내'),
          _buildDataRow('카메라 촬영 고도', '지상 32.4m'),
          _buildDataRow('진단 당시 기온', '섭씨 18도 / 건조'),
        ],
      ),
    );
  }

  // 탭 공통 로우 렌더러
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /* =========== 위치 정보 탭 모듈 =========== */
  Widget _buildLocationTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Icon(Icons.map_outlined, color: Colors.blueGrey[400], size: 48),
          const SizedBox(height: 16),
          const Text('현재 데모(Dummy) 환경에서는 실시간 지도 뷰를 렌더링하지 않습니다.', style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('GPS 좌표: 위도 37.524, 경도 127.038', style: TextStyle(color: _cyanAccent, fontSize: 12)),
        ],
      ),
    );
  }

  /* =========== 작업자 코멘트 탭 모듈 =========== */
  Widget _buildCommentTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: TextField(
              maxLines: null, // 내용 많아지면 밑으로 확장
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '작업 지시 사항이나 현장 코멘트를 남기세요 (서버와 동기화됨)...',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코멘트 저장 성공!')));
              },
              child: Text('저장하기', style: TextStyle(color: _cyanAccent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
