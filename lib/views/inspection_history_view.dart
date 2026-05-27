import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_project_ui/views/inspection_detail_view.dart';
import '../viewmodels/inspection_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/defect.dart';

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

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 서버에서 결함 이력 데이터를 가져옴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InspectionViewModel>(context, listen: false).fetchDefects();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: Consumer<InspectionViewModel>(
                builder: (context, viewModel, child) {
                  // 로딩 중 상태
                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: brandingBlue, strokeWidth: 3),
                    );
                  }

                  // 에러 상태 (리스트가 비어있을 때만)
                  if (viewModel.errorMessage != null && viewModel.defects.isEmpty) {
                    return _buildErrorState(viewModel.errorMessage!);
                  }

                  // 필터링 로직: Defect.statusCode를 기반으로 필터
                  final filteredList = viewModel.defects.where((defect) {
                    if (_selectedFilter == '전체') return true;
                    if (_selectedFilter == '위험' && defect.statusCode == 'CRITICAL') return true;
                    if (_selectedFilter == '주의' && defect.statusCode == 'WARNING') return true;
                    if (_selectedFilter == '양호' && defect.statusCode == 'SAFE') return true;
                    return false;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: brandingBlue,
                    backgroundColor: cardWhite,
                    onRefresh: viewModel.fetchDefects,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(filteredList[index], viewModel);
                      },
                    ),
                  );
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
                '결함 탐지 내역',
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
              '결함 탐지 내역이 없습니다',
              style: TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI 탐지가 완료되면 여기에 결과가\n자동으로 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textLightGrey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // 에러 상태 화면
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _redEmergency.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, color: _redEmergency, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              '오류가 발생했습니다',
              style: TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textLightGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<InspectionViewModel>(context, listen: false).fetchDefects();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandingBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 개별 리스트 아이템 카드 (화이트 테마) - Defect 모델 기반
  Widget _buildHistoryCard(Defect defect, InspectionViewModel viewModel) {
    bool isCritical = defect.statusCode == 'CRITICAL';
    bool isWarning = defect.statusCode == 'WARNING';

    Color statusColor = isCritical ? _redEmergency : (isWarning ? _orangeWarning : _greenSafe);
    String statusText = defect.statusLabel;

    // 날짜 포맷팅
    String dateStr = '${defect.detectionTime.year}-${defect.detectionTime.month.toString().padLeft(2, '0')}-${defect.detectionTime.day.toString().padLeft(2, '0')} ${defect.detectionTime.hour.toString().padLeft(2, '0')}:${defect.detectionTime.minute.toString().padLeft(2, '0')}';

    // 삭제 권한 확인
    final String? userRole = Provider.of<AuthViewModel>(context, listen: false).currentUser?.role;
    final bool canDelete = userRole == 'admin' || userRole == 'super_admin';

    return Dismissible(
      key: Key('defect_${defect.defectId}'),
      direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _redEmergency,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        bool confirmDelete = false;
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('진단 이력 삭제', style: TextStyle(color: textCharcoal, fontWeight: FontWeight.bold)),
            content: Text('이 ${defect.defectType} 결함 이력을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
              style: const TextStyle(color: textLightGrey, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소', style: TextStyle(color: textLightGrey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  confirmDelete = true;
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _redEmergency,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirmDelete) {
          final success = await viewModel.deleteDefect(defect.defectId);
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(viewModel.errorMessage ?? '결함 이력 삭제에 실패했습니다.'),
                backgroundColor: _redEmergency,
              ),
            );
            viewModel.clearError();
            return false;
          } else if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('결함 이력이 성공적으로 삭제되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: brandingBlue,
              ),
            );
            return true;
          }
        }
        return false;
      },
      child: Container(
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
            onTap: () {
              // 카드 터치 시 상세 화면으로 이동 (Defect 객체 전달)
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return FadeTransition(
                      opacity: animation,
                      child: InspectionDetailView(defect: defect),
                    );
                  },
                ),
              );
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 왼쪽 상태 표시 바 + 이미지 영역
                  SizedBox(
                    width: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 이미지가 있으면 네트워크 이미지, 없으면 아이콘 표시
                        if (defect.imageUrl != null && defect.imageUrl!.isNotEmpty)
                          Hero(
                            tag: 'hero_image_${defect.defectId}',
                            child: Image.network(
                              defect.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: bgOffWhite,
                                child: Icon(_getDefectIcon(defect.defectType), color: statusColor, size: 36),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: statusColor.withValues(alpha: 0.08),
                            child: Center(
                              child: Icon(_getDefectIcon(defect.defectType), color: statusColor, size: 36),
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
                                child: Text(defect.defectType,
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
                          Text(defect.comment ?? '코멘트 없음',
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
                                    Flexible(child: Text(dateStr, style: const TextStyle(color: textLightGrey, fontSize: 10), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              // 심각도 표시
                              Row(
                                children: [
                                  Icon(Icons.circle, color: statusColor, size: 8),
                                  const SizedBox(width: 4),
                                  Text(defect.severity ?? '미분류', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  // 결함 타입에 따라 아이콘 반환
  IconData _getDefectIcon(String defectType) {
    final lower = defectType.toLowerCase();
    if (lower.contains('화재') || lower.contains('fire')) return Icons.local_fire_department;
    if (lower.contains('균열') || lower.contains('crack')) return Icons.broken_image;
    if (lower.contains('박리') || lower.contains('spalling')) return Icons.layers;
    if (lower.contains('부식') || lower.contains('corrosion')) return Icons.water_damage;
    return Icons.warning_amber;
  }
}
