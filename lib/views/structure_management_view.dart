import 'package:flutter/material.dart';

class StructureManagementView extends StatelessWidget {
  const StructureManagementView({super.key});

  // ─── 대시보드 동기화 색상 토큰 ───────────────────────────
  static const Color _bgOffWhite  = Color(0xFFF8F9FA);
  static const Color _cardWhite   = Color(0xFFFFFFFF);
  static const Color _charcoal    = Color(0xFF212529);
  static const Color _lightGrey   = Color(0xFF6C757D);
  static const Color _brandingBlue = Color(0xFF3761F3);
  static const Color _borderLight = Color(0xFFDEE2E6);
  
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFFFB020);

  // 더미 구조물 데이터 (로직 보존)
  static final List<Map<String, dynamic>> _dummyStructures = [
    {
      'name': '정보공학관',
      'type': '대학 건물',
      'floors': 5,
      'year': 2008,
      'status': 'good',
      'score': 92,
      'lastInspection': '2026-04-15',
      'issues': 1,
      'icon': Icons.school_rounded,
    },
    {
      'name': '중앙도서관',
      'type': '도서관',
      'floors': 6,
      'year': 2002,
      'status': 'warning',
      'score': 74,
      'lastInspection': '2026-03-28',
      'issues': 3,
      'icon': Icons.local_library_rounded,
    },
    {
      'name': '학생회관',
      'type': '복합 시설',
      'floors': 4,
      'year': 1995,
      'status': 'danger',
      'score': 58,
      'lastInspection': '2026-04-02',
      'issues': 7,
      'icon': Icons.groups_rounded,
    },
    {
      'name': '공학관 A동',
      'type': '연구동',
      'floors': 8,
      'year': 2015,
      'status': 'good',
      'score': 96,
      'lastInspection': '2026-04-20',
      'issues': 0,
      'icon': Icons.precision_manufacturing_rounded,
    },
    {
      'name': '제1기숙사',
      'type': '주거 시설',
      'floors': 10,
      'year': 2010,
      'status': 'warning',
      'score': 81,
      'lastInspection': '2026-04-10',
      'issues': 2,
      'icon': Icons.apartment_rounded,
    },
  ];

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
        title: const Text('구조물 관리', 
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.architecture, color: _brandingBlue, size: 14),
                const SizedBox(width: 4),
                Text('${_dummyStructures.length}개소', 
                    style: const TextStyle(color: _brandingBlue, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderLight, height: 1),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 1. 상단 요약 섹션
          _buildSummaryCards(),
          const SizedBox(height: 32),
          
          // 2. 섹션 타이틀
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(color: _brandingBlue, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('등록된 구조물', 
                  style: TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          
          // 3. 구조물 카드 리스트
          ..._dummyStructures.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStructureCard(s, context),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final good = _dummyStructures.where((s) => s['status'] == 'good').length;
    final warning = _dummyStructures.where((s) => s['status'] == 'warning').length;
    final danger = _dummyStructures.where((s) => s['status'] == 'danger').length;

    return Row(
      children: [
        Expanded(child: _buildMiniStat(Icons.verified_outlined, '양호', '$good', _green)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.warning_amber_rounded, '주의', '$warning', _orange)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.dangerous_outlined, '위험', '$danger', _red)),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
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

  Widget _buildStructureCard(Map<String, dynamic> structure, BuildContext context) {
    final status = structure['status'] as String;
    final score = structure['score'] as int;
    final issues = structure['issues'] as int;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'good': statusColor = _green; statusLabel = '양호'; break;
      case 'warning': statusColor = _orange; statusLabel = '주의'; break;
      case 'danger': statusColor = _red; statusLabel = '위험'; break;
      default: statusColor = _lightGrey; statusLabel = '미정';
    }

    return GestureDetector(
      onTap: () => _showStructureDetail(context, structure, statusColor, statusLabel),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 영역
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(structure['icon'] as IconData, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(structure['name'], 
                          style: const TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${structure['type']}  •  ${structure['floors']}층  •  ${structure['year']}년 준공', 
                          style: const TextStyle(color: _lightGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusLabel, 
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 점수 바 섹션
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('안전 지수', style: TextStyle(color: _charcoal, fontSize: 12, fontWeight: FontWeight.w700)),
                          Text('$score/100', style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: _bgOffWhite,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // 이슈 카운트
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bgOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Column(
                    children: [
                      Text('$issues', 
                          style: TextStyle(color: issues > 0 ? _orange : _green, fontSize: 18, fontWeight: FontWeight.w900)),
                      const Text('이슈', style: TextStyle(color: _lightGrey, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: _borderLight, height: 1),
            const SizedBox(height: 12),
            
            // 하단 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, color: _lightGrey, size: 12),
                    const SizedBox(width: 4),
                    Text('최근 점검: ${structure['lastInspection']}', 
                        style: const TextStyle(color: _lightGrey, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
                const Row(
                  children: [
                    Text('상세 분석', 
                        style: TextStyle(color: _brandingBlue, fontSize: 11, fontWeight: FontWeight.w800)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, color: _brandingBlue, size: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStructureDetail(BuildContext context, Map<String, dynamic> structure, Color statusColor, String statusLabel) {
    final score = structure['score'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(structure['icon'] as IconData, color: statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(structure['name'], 
                            style: const TextStyle(color: _charcoal, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${structure['type']}  •  ${structure['floors']}층  •  ${structure['year']}년 준공', 
                            style: const TextStyle(color: _lightGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // 종합 점수 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _bgOffWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('종합 안전 등급', 
                            style: TextStyle(color: _charcoal, fontSize: 15, fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(statusLabel, 
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _borderLight),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: score / 100,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('안전 점수', style: TextStyle(color: _lightGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$score / 100', 
                            style: const TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('점검 항목별 상세 데이터', 
                  style: TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCheckItem('외벽 균열 및 탈락 상태', score > 80 ? 'pass' : score > 60 ? 'warning' : 'fail'),
                    _buildCheckItem('주요 구조부(기둥, 보) 건전성', score > 70 ? 'pass' : 'warning'),
                    _buildCheckItem('철근 부식 및 피복 두께', score > 85 ? 'pass' : score > 65 ? 'warning' : 'fail'),
                    _buildCheckItem('옥상/지하 방수층 노후도', score > 75 ? 'pass' : 'warning'),
                    _buildCheckItem('부등 침하 및 지반 안정성', 'pass'),
                    _buildCheckItem('소방/전기 설비 안전 상태', score > 60 ? 'pass' : 'fail'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckItem(String title, String result) {
    IconData icon;
    Color color;
    String label;
    switch (result) {
      case 'pass': icon = Icons.check_circle_rounded; color = _green; label = '양호'; break;
      case 'warning': icon = Icons.error_rounded; color = _orange; label = '주의'; break;
      default: icon = Icons.cancel_rounded; color = _red; label = '이상';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: _borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: _charcoal, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
