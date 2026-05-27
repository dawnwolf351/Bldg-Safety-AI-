import 'package:flutter/material.dart';

class SafetyGradeView extends StatelessWidget {
  const SafetyGradeView({super.key});

  // 대시보드와 통일된 프리미엄 화이트 테마 토큰
  static const Color bgOffWhite = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textCharcoal = Color(0xFF1A1D21);
  static const Color textLightGrey = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  // 등급별 색상 매핑
  static const Map<String, Color> gradeColors = {
    'A': Color(0xFF22C55E), // 우수
    'B': Color(0xFF3B82F6), // 양호
    'C': Color(0xFFF59E0B), // 보통
    'D': Color(0xFFF97316), // 미흡
    'E': Color(0xFFEF4444), // 불량
  };

  // 하드코딩된 안전등급 기준표 데이터
  static const List<Map<String, String>> safetyGrades = [
    {
      'grade': 'A',
      'label': '우수',
      'state': '문제없음',
      'description': '문제점이 없는 최상의 상태'
    },
    {
      'grade': 'B',
      'label': '양호',
      'state': '경미한 결함',
      'description': '보조부재에 경미한 결함이 발생하였으나, 전체적인 시설물 기능 발휘에는 지장이 없는 상태'
    },
    {
      'grade': 'C',
      'label': '보통',
      'state': '보수 필요',
      'description': '주요부재에 경미한 결함 또는 보조부재에 광범위한 결함이 발생하여 보수가 필요한 상태'
    },
    {
      'grade': 'D',
      'label': '미흡',
      'state': '긴급 보수',
      'description': '주요부재에 결함이 발생하여 긴급한 보수 및 보강이 필요하며, 사용제한 여부를 결정해야 하는 상태'
    },
    {
      'grade': 'E',
      'label': '불량',
      'state': '사용 금지',
      'description': '주요부재에 심각한 결함이 발생하여 시설물의 안전에 위험이 있어 즉각 사용을 금지하고 보강 또는 개축을 해야 하는 상태'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgOffWhite,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '안전등급 기준표',
          style: TextStyle(color: textCharcoal, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: textCharcoal),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderLight, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SOC 시설물 안전 진단 기준',
              style: TextStyle(color: textCharcoal, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '국가 기준에 따른 구조물의 안전 상태 등급과 각 등급이 의미하는 바를 확인하세요.',
              style: TextStyle(color: textLightGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ...safetyGrades.map((gradeData) => _buildGradeCard(gradeData)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(Map<String, String> data) {
    final grade = data['grade']!;
    final label = data['label']!;
    final state = data['state']!;
    final description = data['description']!;
    
    final color = gradeColors[grade] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 등급 색상 바
            Container(
              width: 80,
              color: color.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 우측 설명 텍스트
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state,
                      style: const TextStyle(
                        color: textCharcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: textLightGrey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
