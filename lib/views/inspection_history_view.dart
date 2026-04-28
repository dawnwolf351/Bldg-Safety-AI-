import 'package:flutter/material.dart';
import 'package:capstone_project_ui/views/inspection_detail_view.dart';

class InspectionHistoryView extends StatefulWidget {
  const InspectionHistoryView({super.key});

  @override
  State<InspectionHistoryView> createState() => _InspectionHistoryViewState();
}

class _InspectionHistoryViewState extends State<InspectionHistoryView> {
  String _selectedFilter = '전체';
  final List<Map<String, dynamic>> _filters = [
    {'label': '전체', 'color': Colors.white},
    {'label': '위험', 'color': const Color(0xFFFF3B30)},
    {'label': '주의', 'color': const Color(0xFFFF9F0A)},
    {'label': '양호', 'color': const Color(0xFF34C759)},
  ];

  final Color _navyCard = const Color(0xFF1E293B);
  final Color _cyanAccent = const Color(0xFF06B6D4);
  final Color _redEmergency = const Color(0xFFFF3B30);
  final Color _orangeWarning = const Color(0xFFFF9F0A);
  final Color _greenSafe = const Color(0xFF34C759);

  // 시각화 목적의 더미 데이터 목록
  final List<Map<String, dynamic>> _dummyHistory = [
    {
      'title': '성수대교 북단 교각 3번',
      'subtitle': '균열 및 철근 노출 2건 감지',
      'date': '2026. 04. 02  14:30',
      'status': 'CRITICAL',
      'confidence': '98%',
      'imageUrl': 'https://picsum.photos/seed/crack1/400/300',
    },
    {
      'title': '서해대교 주탑 하부 정밀진단',
      'subtitle': '표면 박리 및 미세 균열 1건',
      'date': '2026. 04. 01  09:15',
      'status': 'WARNING',
      'confidence': '75%',
      'imageUrl': 'https://picsum.photos/seed/drone5/400/300',
    },
    {
      'title': '잠실대교 남단 상판',
      'subtitle': '특이사항 없음 (안전)',
      'date': '2026. 03. 28  11:00',
      'status': 'SAFE',
      'confidence': '99%',
      'imageUrl': 'https://picsum.photos/seed/bridge7/400/300',
    },
    {
      'title': 'A-1 구역 노후 아파트 외벽',
      'subtitle': '심각한 외벽 크랙 및 누수 흔적',
      'date': '2026. 03. 25  15:45',
      'status': 'CRITICAL',
      'confidence': '92%',
      'imageUrl': 'https://picsum.photos/seed/wall2/400/300',
    },
    {
      'title': '가양대교 7번 교각 점검',
      'subtitle': '특이사항 없음 (안전)',
      'date': '2026. 03. 21  10:20',
      'status': 'SAFE',
      'confidence': '96%',
      'imageUrl': 'https://picsum.photos/seed/safe9/400/300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 탭 클릭에 따른 리스트 필터링
        List<Map<String, dynamic>> filteredList = _dummyHistory.where((item) {
      if (_selectedFilter == '전체') return true;
      if (_selectedFilter == '위험' && item['status'] == 'CRITICAL') return true;
      if (_selectedFilter == '주의' && item['status'] == 'WARNING') return true;
      if (_selectedFilter == '양호' && item['status'] == 'SAFE') return true;
      return false;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(filteredList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 상단 헤더
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
                child: Icon(Icons.assignment_outlined, color: _cyanAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('진단 내역', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('INSPECTION HISTORY', style: TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.blueGrey[300]),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('검색 기능은 추후 연동됩니다.')));
            },
          )
        ],
      ),
    );
  }

  // 가로 스크롤 필터 바
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _filters.map((filter) {
          bool isSelected = _selectedFilter == filter['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              showCheckmark: filter['label'] == '전체',
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter['label'] != '전체') ...[
                    Icon(Icons.circle, size: 10, color: filter['color']),
                    const SizedBox(width: 6),
                  ],
                  Text(filter['label'], style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey[300],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  )),
                ],
              ),
              selected: isSelected,
              selectedColor: _cyanAccent.withValues(alpha: 0.2),
              backgroundColor: _navyCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _cyanAccent : Colors.blueGrey.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter['label'];
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 개별 리스트 아이템 카드
  Widget _buildHistoryCard(Map<String, dynamic> data) {
    bool isCritical = data['status'] == 'CRITICAL';
    bool isWarning = data['status'] == 'WARNING';

    Color statusColor = isCritical ? _redEmergency : (isWarning ? _orangeWarning : _greenSafe);
    String statusText = isCritical ? '위험 감지' : (isWarning ? '주의 필요' : '안전(정상)');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? _redEmergency.withValues(alpha: 0.4) : Colors.blueGrey.withValues(alpha: 0.2),
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: isCritical ? [
          BoxShadow(color: _redEmergency.withValues(alpha: 0.15), spreadRadius: 0, blurRadius: 10)
        ] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () { // 카드 터치 시 인터랙션 (Hero 화면 전환)
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 600),
                reverseTransitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: InspectionDetailView(inspectionData: data),
                  );
                },
              ),
            );
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 왼쪽 썸네일 이미지 영역
                SizedBox(
                  width: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'hero_image_${data['title']}', // 상세 화면과 매칭될 Hero 태그
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.blueGrey[800],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      ),
                      // 이미지와 글씨 겹치는 부분 그라데이션 자연스럽게 블렌딩
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, _navyCard],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // 위험(CRITICAL)일 때 뜨는 타겟팅 박스 시각 연출
                      if (isCritical)
                        Positioned(
                          top: 15, right: 15, bottom: 15, left: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: _redEmergency, width: 2),
                              color: _redEmergency.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 오른쪽 텍스트 정보 영역
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(data['title'],
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 위험 등급 배지
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(data['subtitle'],
                          style: TextStyle(color: isCritical ? Colors.red[200] : Colors.blueGrey[300], fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 일시
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.blueGrey[400], size: 12),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(data['date'], style: TextStyle(color: Colors.blueGrey[400], fontSize: 10), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            // AI 신뢰도 표시
                            Row(
                              children: [
                                Icon(Icons.psychology, color: _cyanAccent, size: 12),
                                const SizedBox(width: 4),
                                Text('AI 신뢰도 ${data['confidence']}', style: TextStyle(color: _cyanAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
