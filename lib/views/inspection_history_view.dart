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

  // 화이트 테마 디자인 토큰 (대시보드와 통일)
  static const Color bgOffWhite = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textCharcoal = Color(0xFF1A1D21);
  static const Color textLightGrey = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color brandingBlue = Color(0xFF2563EB);

  final Color _redEmergency = const Color(0xFFFF3B30);
  final Color _orangeWarning = const Color(0xFFFF9F0A);
  final Color _greenSafe = const Color(0xFF34C759);

  // 시각화 목적의 더미 데이터 목록 삭제 완료 (실제 DB 연동 대기)
  final List<Map<String, dynamic>> _dummyHistory = [];

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

    return Container(
      color: bgOffWhite,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            _buildFilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
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
      ),
    );
  }

  // 상단 헤더 (화이트 테마)
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: brandingBlue, size: 28),
              SizedBox(width: 8),
              Text(
                '진단 내역',
                style: TextStyle(color: textCharcoal, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 가로 스크롤 필터 바 (화이트 테마)
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
              checkmarkColor: brandingBlue,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter['label'] != '전체') ...[
                    Icon(Icons.circle, size: 8, color: filter['color']),
                    const SizedBox(width: 6),
                  ],
                  Text(filter['label'], style: TextStyle(
                    color: isSelected ? brandingBlue : textLightGrey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  )),
                ],
              ),
              selected: isSelected,
              selectedColor: brandingBlue.withValues(alpha: 0.1),
              backgroundColor: cardWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? brandingBlue : borderLight,
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

  // 데이터 없을 때 빈 화면 상태
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandingBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, color: brandingBlue.withValues(alpha: 0.4), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              '진단 내역이 없습니다',
              style: TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI 진단이 완료되면 여기에 결과가\n자동으로 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textLightGrey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // 개별 리스트 아이템 카드 (화이트 테마)
  Widget _buildHistoryCard(Map<String, dynamic> data) {
    bool isCritical = data['status'] == 'CRITICAL';
    bool isWarning = data['status'] == 'WARNING';

    Color statusColor = isCritical ? _redEmergency : (isWarning ? _orangeWarning : _greenSafe);
    String statusText = isCritical ? '위험 감지' : (isWarning ? '주의 필요' : '안전(정상)');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? _redEmergency.withValues(alpha: 0.3) : borderLight,
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, 2), blurRadius: 8),
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
                  width: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'hero_image_${data['title']}', // 상세 화면과 매칭될 Hero 태그
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: bgOffWhite,
                            child: const Icon(Icons.image_not_supported, color: textLightGrey),
                          ),
                        ),
                      ),
                      // 이미지와 글씨 겹치는 부분 그라데이션 자연스럽게 블렌딩
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, cardWhite],
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
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
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
                                style: const TextStyle(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 위험 등급 배지
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(data['subtitle'],
                          style: const TextStyle(color: textLightGrey, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 일시
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: textLightGrey, size: 12),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(data['date'], style: const TextStyle(color: textLightGrey, fontSize: 10), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                            // AI 신뢰도 표시
                            Row(
                              children: [
                                const Icon(Icons.psychology, color: brandingBlue, size: 12),
                                const SizedBox(width: 4),
                                Text('AI 신뢰도 ${data['confidence']}', style: const TextStyle(color: brandingBlue, fontSize: 10, fontWeight: FontWeight.w600)),
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
