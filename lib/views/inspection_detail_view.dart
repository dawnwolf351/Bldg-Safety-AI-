import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/defect.dart';
import '../models/building.dart';
import '../viewmodels/building_viewmodel.dart';
import '../viewmodels/inspection_viewmodel.dart';
import '../services/report_service.dart';
import '../utils/alert_utils.dart';
import '../services/notification_service.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class InspectionDetailView extends StatefulWidget {
  final Defect defect;

  // 기존 호환성을 위한 named parameter (하위 호환)
  final Map<String, dynamic>? inspectionData;

  const InspectionDetailView({super.key, required this.defect, this.inspectionData});

  @override
  State<InspectionDetailView> createState() => _InspectionDetailViewState();
}

class _InspectionDetailViewState extends State<InspectionDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _commentCtrl;

  // 대시보드 및 진단 내역 화면과 통일된 프리미엄 화이트 테마 토큰
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
    _tabController = TabController(length: 3, vsync: this);
    _commentCtrl = TextEditingController(text: widget.defect.comment ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defect = widget.defect;
    bool isCritical = defect.statusCode == 'CRITICAL';
    bool isWarning = defect.statusCode == 'WARNING';
    Color statusColor = isCritical ? _redEmergency : (isWarning ? _orangeWarning : _greenSafe);

    final String? userRole = Provider.of<AuthViewModel>(context, listen: false).currentUser?.role;
    final bool canEditOrDelete = userRole == 'admin' || userRole == 'super_admin';

    // 날짜 포맷팅
    String dateStr = '${defect.detectionTime.year}-${defect.detectionTime.month.toString().padLeft(2, '0')}-${defect.detectionTime.day.toString().padLeft(2, '0')} ${defect.detectionTime.hour.toString().padLeft(2, '0')}:${defect.detectionTime.minute.toString().padLeft(2, '0')}:${defect.detectionTime.second.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: bgOffWhite,
      // 깔끔한 투명 앱바
      appBar: AppBar(
        backgroundColor: bgOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textCharcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '상세 진단 정보',
          style: TextStyle(color: textCharcoal, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          // AI 자동 탐지(confidence != null)가 아닌 수동 추가 결함만 수정 가능 (관리자 권한 필요)
          if (defect.confidence == null && canEditOrDelete)
            TextButton.icon(
              onPressed: () => _showEditDefectModal(context, defect),
              icon: const Icon(Icons.edit_note, color: brandingBlue, size: 20),
              label: const Text('수정', style: TextStyle(color: brandingBlue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 대형 결함 이미지 또는 아이콘 영역
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 4),
                              blurRadius: 16,
                            ),
                          ],
                          border: Border.all(color: borderLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: defect.imageUrl != null && defect.imageUrl!.isNotEmpty
                              ? Hero(
                                  tag: 'hero_image_${defect.defectId}',
                                  child: Image.network(
                                    defect.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(_getDefectIcon(defect.defectType), color: statusColor, size: 64),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(_getDefectIcon(defect.defectType), color: statusColor, size: 72),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 결함 제목
                    Center(
                      child: Text(
                        defect.defectType,
                        style: const TextStyle(
                          color: textCharcoal,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. 상태 요약 큰 뱃지 (화이트 테마 매칭)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(isCritical ? Icons.warning_rounded : (isWarning ? Icons.info_outline : Icons.check_circle_outline), color: statusColor, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  defect.statusCode,
                                  style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AI 소견: ${defect.defectType} | 심각도: ${defect.severity ?? "미분류"}',
                                  style: const TextStyle(color: textCharcoal, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. 3종 스펙 정보 탭 바 (화이트 테마 매칭)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderLight, width: 1.5)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: brandingBlue,
                        indicatorWeight: 3,
                        labelColor: brandingBlue,
                        unselectedLabelColor: textLightGrey,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: -0.3),
                        tabs: const [
                          Tab(text: '세부 데이터'),
                          Tab(text: '위치 정보'),
                          Tab(text: '메모'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. 스펙 정보 탭 내용 (화이트 테마 매칭)
                    SizedBox(
                      height: 240,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildDataTab(defect, dateStr),
                          _buildLocationTab(defect),
                          _buildCommentTab(defect, canEditOrDelete),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. 하단 고정 액션 바 (화이트 테마 매칭)
            Container(
              decoration: BoxDecoration(
                color: cardWhite,
                border: const Border(top: BorderSide(color: borderLight, width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // 스낵바로 피드백
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('보고서를 생성하는 중입니다...', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: brandingBlue, duration: Duration(seconds: 1)),
                        );
                        
                        // 건물 정보 가져오기 (보고서에 입력)
                        final buildingViewModel = Provider.of<BuildingViewModel>(context, listen: false);
                        final building = buildingViewModel.buildings.where((b) => b.id == defect.buildingId).firstOrNull;

                        // 실제 보고서 생성 로직 호출
                        await ReportService.generateDefectReport(
                          context, 
                          defect,
                          buildingName: building?.buildingName,
                          buildingLocation: building?.location,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('보고서 (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandingBlue,
                        side: const BorderSide(color: brandingBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isCritical) {
                          // 1. 앱 내 긴급 팝업 + 사이렌 실행 (기존 로직 유지)
                          EmergencyAlert.show(context);

                          // 2. 실제 아이폰 시스템 알림 발송
                          final settingsVm = Provider.of<SettingsViewModel>(context, listen: false);
                          await NotificationService().triggerAlert(
                            pushEnabled: settingsVm.pushNotifications,
                            soundVibrationEnabled: settingsVm.soundVibration,
                            doNotDisturbEnabled: settingsVm.doNotDisturb,
                            title: '🚨 긴급 위험 감지!',
                            body: '[${defect.defectType}] ${defect.severity ?? "심각"} 등급 결함이 탐지되었습니다. 즉각 대응이 필요합니다.',
                            isEmergency: true,
                          );
                        } else {
                          if (!canEditOrDelete) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('접근 거부: 결함 삭제/조치 완료는 관리자(레벨 2) 이상만 가능합니다.', style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Color(0xFFFF3B30),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          // showDialog(await) 이전에 context 의존 객체 모두 캡처
                          final vm = Provider.of<InspectionViewModel>(
                              context, listen: false);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);

                          // 조치 완료 확인 다이얼로그
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: borderLight)),
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Color(0xFF34C759), size: 22),
                                  SizedBox(width: 8),
                                  Text('조치 완료 확인',
                                      style: TextStyle(
                                          color: textCharcoal,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: Text(
                                '"${defect.defectType}" 결함을 조치 완료 처리하면\n목록에서 삭제되며 복구할 수 없습니다.\n계속하시겠습니까?',
                                style: const TextStyle(
                                    color: textLightGrey,
                                    height: 1.5,
                                    fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: const Text('취소',
                                      style: TextStyle(
                                          color: textLightGrey,
                                          fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _greenSafe,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('조치 완료',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;
                          if (!mounted) return;

                          final success =
                              await vm.deleteDefect(defect.defectId);

                          if (!mounted) return;

                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✅ 조치가 완료되어 결함 이력에서 삭제되었습니다.',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: Color(0xFF34C759),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            navigator.pop(); // 이전 목록 화면으로 복귀
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    vm.errorMessage ??
                                        '❌ 조치 완료 처리에 실패했습니다. 다시 시도해 주세요.',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: _redEmergency,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            vm.clearError();
                          }
                        }
                      },
                      icon: Icon(isCritical ? Icons.notifications_active : Icons.check_circle_outline, size: 20),
                      label: Text(isCritical ? '긴급 알림 띄우기' : '조치 완료 마킹', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /* =========== 세부 데이터 탭 모듈 =========== */
  Widget _buildDataTab(Defect defect, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDataRow('검사 일시', dateStr),
          _buildDataRow('결함 종류', defect.defectType),
          _buildDataRow('심각도', defect.severity ?? '미분류'),
          _buildDataRow('연결 건물 ID', '${defect.buildingId}'),
          _buildDataRow('탐지 기기 ID', '${defect.deviceId}'),
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
          Text(label, style: const TextStyle(color: textLightGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: textCharcoal, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<LatLng?> _fetchBuildingLocation(int buildingId) async {
    try {
      final buildingViewModel = Provider.of<BuildingViewModel>(context, listen: false);
      if (buildingViewModel.buildings.isEmpty) {
        await buildingViewModel.fetchBuildings();
      }
      
      final Building? building = buildingViewModel.buildings.where((b) => b.id == buildingId).firstOrNull;
      
      if (building != null && building.location.isNotEmpty) {
        List<Location> locations = await locationFromAddress(building.location);
        if (locations.isNotEmpty) {
          return LatLng(locations.first.latitude, locations.first.longitude);
        }
      }
    } catch (e) {
      debugPrint('위치 조회 오류: $e');
    }
    // 건물이 없거나 지오코딩 실패 시 null 반환
    return null;
  }

  /* =========== 수동 추가 결함 수정 모달 =========== */
  void _showEditDefectModal(BuildContext context, Defect currentDefect) {
    TextEditingController editTypeCtrl = TextEditingController(text: currentDefect.defectType);
    TextEditingController editCommentCtrl = TextEditingController(text: currentDefect.comment ?? '');
    File? pickedImageFile;

    // 기존 심각도 값을 A~E로 매핑
    String currentSev = currentDefect.severity?.toUpperCase() ?? 'A';
    if (['경미', 'A'].contains(currentSev)) {
      currentSev = 'A';
    } else if (['주의', 'C'].contains(currentSev)) {
      currentSev = 'C';
    } else if (['심각', 'E'].contains(currentSev)) {
      currentSev = 'E';
    }
    
    if (!['A','B','C','D','E'].contains(currentSev)) {
      currentSev = 'A';
    }
    String selectedSeverity = currentSev;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              margin: EdgeInsets.only(
                top: 40,
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '결함 이력 수정',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textCharcoal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: textLightGrey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 사진 첨부 (선택) - 현재 이미지 또는 새로 고른 이미지
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        showModalBottomSheet(
                          context: ctx,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (modalCtx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const CircleAvatar(backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.photo_library_outlined, color: brandingBlue)),
                                  title: const Text('갤러리에서 선택', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () async {
                                    Navigator.pop(modalCtx);
                                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                    if (picked != null) setModalState(() => pickedImageFile = File(picked.path));
                                  },
                                ),
                                ListTile(
                                  leading: const CircleAvatar(backgroundColor: Color(0xFFFFF0F0), child: Icon(Icons.camera_alt_outlined, color: Colors.redAccent)),
                                  title: const Text('카메라로 촬영', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () async {
                                    Navigator.pop(modalCtx);
                                    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                    if (picked != null) setModalState(() => pickedImageFile = File(picked.path));
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bgOffWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderLight),
                        ),
                        child: pickedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(pickedImageFile!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setModalState(() => pickedImageFile = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (currentDefect.imageUrl != null && currentDefect.imageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(currentDefect.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: textLightGrey, size: 40)),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {}, // 기존 이미지를 지우진 않고 덮어씌움 안내
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: brandingBlue.withValues(alpha: 0.5), size: 40),
                                      const SizedBox(height: 8),
                                      const Text('사진 첨부 (선택)', style: TextStyle(color: textLightGrey, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('갤러리 또는 카메라', style: TextStyle(color: brandingBlue.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 결함 유형 직접 입력
                    const Text('결함 유형', style: TextStyle(fontWeight: FontWeight.bold, color: textCharcoal, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: editTypeCtrl,
                      style: const TextStyle(fontSize: 15, color: textCharcoal),
                      decoration: InputDecoration(
                        hintText: '예: 균열, 화재, 박리, 침수 등',
                        hintStyle: const TextStyle(color: textLightGrey, fontSize: 14),
                        filled: true,
                        fillColor: bgOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: brandingBlue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 심각도 선택 (드롭다운)
                    const Text('심각도', style: TextStyle(fontWeight: FontWeight.bold, color: textCharcoal, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderLight),
                        borderRadius: BorderRadius.circular(12),
                        color: bgOffWhite,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSeverity,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: textLightGrey),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('A (우수 / 매우 안전)', style: TextStyle(fontSize: 15, color: textCharcoal))),
                            DropdownMenuItem(value: 'B', child: Text('B (양호 / 안전)', style: TextStyle(fontSize: 15, color: textCharcoal))),
                            DropdownMenuItem(value: 'C', child: Text('C (보통 / 주의)', style: TextStyle(fontSize: 15, color: textCharcoal))),
                            DropdownMenuItem(value: 'D', child: Text('D (미흡 / 위험)', style: TextStyle(fontSize: 15, color: textCharcoal))),
                            DropdownMenuItem(value: 'E', child: Text('E (불량 / 매우 위험)', style: TextStyle(fontSize: 15, color: textCharcoal))),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setModalState(() => selectedSeverity = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 메모 입력
                    const Text('메모 (선택)', style: TextStyle(fontWeight: FontWeight.bold, color: textCharcoal, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: editCommentCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15, color: textCharcoal),
                      decoration: InputDecoration(
                        hintText: '결함에 대한 추가 설명을 입력하세요.',
                        hintStyle: const TextStyle(color: textLightGrey, fontSize: 14),
                        filled: true,
                        fillColor: bgOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: brandingBlue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 수정 완료 버튼
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          final vm = Provider.of<InspectionViewModel>(context, listen: false);
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          
                          // 수정 API 호출 (PUT)
                          bool success = await vm.updateDefect(
                            defectId: currentDefect.defectId,
                            defectType: editTypeCtrl.text.trim().isEmpty ? '알 수 없음' : editTypeCtrl.text.trim(),
                            severity: selectedSeverity,
                            comment: editCommentCtrl.text.trim(),
                            imageFilePath: pickedImageFile?.path,
                          );
                          
                          if (!mounted) return;
                          
                          if (success) {
                            nav.pop(); // 모달 닫기
                            nav.pop(); // 기존 상세 화면도 닫고 목록으로 복귀(새로고침 반영)
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('✅ 결함 정보가 성공적으로 수정되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Color(0xFF34C759),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(vm.errorMessage ?? '❌ 수정 실패', style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: const Color(0xFFFF3B30),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandingBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* =========== 위치 정보 탭 모듈 =========== */
  Widget _buildLocationTab(Defect defect) {
    return FutureBuilder<LatLng?>(
      future: _fetchBuildingLocation(defect.buildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLight),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: brandingBlue),
            ),
          );
        }

        final latLng = snapshot.data;
        
        // 지오코딩 실패 (잘못된 주소 등)
        if (latLng == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _redEmergency),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: _redEmergency, size: 40),
                  const SizedBox(height: 10),
                  const Text('해당 건물의 주소를 지도에서 찾을 수 없습니다.\n건물 관리에서 정확한 도로명 주소를 입력해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textCharcoal, fontWeight: FontWeight.bold, height: 1.5)),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: latLng,
                    zoom: 16.0,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('building_${defect.buildingId}'),
                      position: latLng,
                      infoWindow: InfoWindow(
                        title: '건물 ID: ${defect.buildingId}',
                        snippet: '탐지 기기(Jetson): ${defect.deviceId}',
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // 상단 안내 오버레이
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '건물 ID: ${defect.buildingId} 에서 탐지된 결함입니다.',
                          style: const TextStyle(color: textCharcoal, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '탐지 기기(Jetson) ID: ${defect.deviceId}',
                          style: const TextStyle(color: brandingBlue, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentTab(Defect defect, bool canEditOrDelete) {
    bool isAiDetected = defect.confidence != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              maxLines: null,
              readOnly: isAiDetected,
              style: TextStyle(
                  color: isAiDetected ? textLightGrey : textCharcoal, 
                  fontSize: 13, 
                  height: 1.5),
              decoration: InputDecoration(
                hintText: isAiDetected 
                    ? 'AI가 자동 탐지한 결함은 코멘트를 수정할 수 없습니다.' 
                    : '작업자 코멘트나 메모를 자유롭게 남기세요 (서버와 동기화됨)...',
                hintStyle: const TextStyle(color: textLightGrey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (!isAiDetected)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  if (!canEditOrDelete) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('접근 거부: 결함 메모 수정은 관리자(레벨 2) 이상만 가능합니다.', style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Color(0xFFFF3B30),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final newComment = _commentCtrl.text.trim();
                  
                  final messenger = ScaffoldMessenger.of(context);
                  final vm = Provider.of<InspectionViewModel>(context, listen: false);
                  
                  messenger.showSnackBar(
                    const SnackBar(content: Text('메모를 저장 중입니다...'), duration: Duration(milliseconds: 500)),
                  );

                  final success = await vm.updateDefectComment(defect.defectId, newComment);
                  if (!mounted) return;

                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('메모가 서버에 성공적으로 저장되었습니다! ✅', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: brandingBlue),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('메모 저장에 실패했습니다. ❌', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('저장하기', style: TextStyle(color: brandingBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            )
        ],
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
