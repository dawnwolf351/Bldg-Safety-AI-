import 'package:flutter/material.dart';

class StructureManagementView extends StatelessWidget {
  const StructureManagementView({super.key});

  static const Color _navy = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFFFB020);

  // 더미 구조물 데이터
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
      'icon': Icons.school,
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
      'icon': Icons.local_library,
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
      'icon': Icons.groups,
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
      'icon': Icons.precision_manufacturing,
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
      'icon': Icons.apartment,
    },
  ];

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
            Text('구조물 관리', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('STRUCTURE MANAGEMENT', style: TextStyle(color: _cyan, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.architecture, color: _cyan, size: 14),
                const SizedBox(width: 4),
                Text('${_dummyStructures.length}개소', style: const TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // 상단 요약
          _buildSummaryCards(),
          const SizedBox(height: 24),
          const Text('등록된 구조물', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('REGISTERED STRUCTURES', style: TextStyle(color: _cyan, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          // 구조물 카드 리스트
          ..._dummyStructures.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildStructureCard(Map<String, dynamic> structure, BuildContext context) {
    final status = structure['status'] as String;
    final score = structure['score'] as int;
    final issues = structure['issues'] as int;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'good':
        statusColor = _green;
        statusLabel = '양호';
        break;
      case 'warning':
        statusColor = _orange;
        statusLabel = '주의';
        break;
      case 'danger':
        statusColor = _red;
        statusLabel = '위험';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '미정';
    }

    return GestureDetector(
      onTap: () => _showStructureDetail(context, structure, statusColor, statusLabel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(structure['icon'] as IconData, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(structure['name'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${structure['type']}  •  ${structure['floors']}층  •  ${structure['year']}년 준공', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                // 상태 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 점수 바 + 정보
            Row(
              children: [
                // 안전 점수 바
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('안전 점수', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                          Text('$score/100', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: _navy,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 발견 이슈
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('$issues', style: TextStyle(color: issues > 0 ? _orange : _green, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('이슈', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 하단 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 11),
                    const SizedBox(width: 4),
                    Text('최근 점검: ${structure['lastInspection']}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
                Row(
                  children: [
                    Text('상세 보기', style: TextStyle(color: _cyan.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: _cyan.withValues(alpha: 0.7), size: 16),
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
          height: MediaQuery.of(context).size.height * 0.7,
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
              const SizedBox(height: 20),
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(structure['icon'] as IconData, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(structure['name'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${structure['type']}  •  ${structure['floors']}층  •  ${structure['year']}년 준공', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 점검 결과 요약
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('종합 안전 등급', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: _navy,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('안전 점수', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        Text('$score / 100', style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 점검 항목
              const Text('점검 항목별 상세', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCheckItem('외벽 균열 검사', score > 80 ? 'pass' : score > 60 ? 'warning' : 'fail'),
                    _buildCheckItem('기둥 구조 점검', score > 70 ? 'pass' : 'warning'),
                    _buildCheckItem('철근 부식도 측정', score > 85 ? 'pass' : score > 65 ? 'warning' : 'fail'),
                    _buildCheckItem('방수층 상태 확인', score > 75 ? 'pass' : 'warning'),
                    _buildCheckItem('지반 침하 여부', 'pass'),
                    _buildCheckItem('소방 설비 점검', score > 60 ? 'pass' : 'fail'),
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
      case 'pass':
        icon = Icons.check_circle;
        color = _green;
        label = '양호';
        break;
      case 'warning':
        icon = Icons.error;
        color = _orange;
        label = '주의';
        break;
      default:
        icon = Icons.cancel;
        color = _red;
        label = '이상';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
