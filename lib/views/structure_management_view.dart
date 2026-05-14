import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/building_viewmodel.dart';
import '../models/building.dart';
import '../theme/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class StructureManagementView extends StatefulWidget {
  const StructureManagementView({super.key});

  @override
  State<StructureManagementView> createState() => _StructureManagementViewState();
}

class _StructureManagementViewState extends State<StructureManagementView> {
  static const Color _bgOffWhite   = AppColors.bgOffWhite;
  static const Color _cardWhite    = AppColors.cardWhite;
  static const Color _charcoal     = AppColors.charcoal;
  static const Color _lightGrey    = AppColors.lightGrey;
  static const Color _brandingBlue = AppColors.brandingBlue;
  static const Color _borderLight  = AppColors.borderLight;
  static const Color _green        = AppColors.statusGreen;
  static const Color _red          = AppColors.statusRed;
  static const Color _orange       = AppColors.statusOrange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuildingViewModel>().fetchBuildings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authVm.currentUser?.role == 'admin' || authVm.currentUser?.role == 'super_admin';

    return Consumer<BuildingViewModel>(
      builder: (context, vm, _) {
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
            title: const Text('건물 관리',
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
                    const Icon(Icons.domain_rounded, color: _brandingBlue, size: 14),
                    const SizedBox(width: 4),
                    Text('${vm.buildings.length}개소',
                        style: const TextStyle(color: _brandingBlue, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: _borderLight),
            ),
          ),
          floatingActionButton: isAdmin 
            ? FloatingActionButton.extended(
                onPressed: () => _showAddBuildingSheet(context, vm),
                backgroundColor: _brandingBlue,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('건물 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator(color: _brandingBlue))
              : vm.buildings.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      children: [
                        _buildSummaryCards(vm.buildings),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Container(
                              width: 4, height: 16,
                              decoration: BoxDecoration(color: _brandingBlue, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 8),
                            const Text('등록된 건물',
                                style: TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...vm.buildings.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildBuildingCard(b, context, vm),
                        )),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _brandingBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.domain_add_rounded, color: _brandingBlue, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('등록된 건물이 없습니다', style: TextStyle(color: _charcoal, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('하단의 "건물 추가" 버튼으로\n첫 번째 건물을 등록해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _lightGrey, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Building> buildings) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat(Icons.domain_rounded, '전체', '${buildings.length}', _brandingBlue)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.event_available_rounded, '완공일 등록', '${buildings.where((b) => b.completionDate != null).length}', _green)),
        const SizedBox(width: 10),
        Expanded(child: _buildMiniStat(Icons.pending_rounded, '미등록', '${buildings.where((b) => b.completionDate == null).length}', _orange)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: _charcoal, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _lightGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(Building building, BuildContext context, BuildingViewModel vm) {
    return GestureDetector(
      onTap: () => _showBuildingDetail(context, building, vm),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _brandingBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.domain_rounded, color: _brandingBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(building.buildingName,
                          style: const TextStyle(color: _charcoal, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: _lightGrey, size: 12),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(building.location,
                                style: const TextStyle(color: _lightGrey, fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: const Text('등록됨', style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: _borderLight, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: _lightGrey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      building.completionDate != null ? '완공일: ${building.completionDate}' : '완공일 미등록',
                      style: const TextStyle(color: _lightGrey, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text('상세 보기', style: TextStyle(color: _brandingBlue, fontSize: 11, fontWeight: FontWeight.w800)),
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

  void _showBuildingDetail(BuildContext context, Building building, BuildingViewModel vm) {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authVm.currentUser?.role == 'admin' || authVm.currentUser?.role == 'super_admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _brandingBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.domain_rounded, color: _brandingBlue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(building.buildingName,
                          style: const TextStyle(color: _charcoal, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(building.location,
                          style: const TextStyle(color: _lightGrey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.tag_rounded, 'Building ID', '#${building.id}'),
            _detailRow(Icons.location_city_rounded, '위치', building.location),
            _detailRow(Icons.event_rounded, '완공일', building.completionDate ?? '미등록'),
            _detailRow(Icons.access_time_rounded, '등록일', building.createdAt ?? '-'),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BuildingMapWidget(address: building.location),
              ),
            ),
            const SizedBox(height: 12),
            if (isAdmin)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddBuildingSheet(context, vm, editBuilding: building);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('수정'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandingBlue,
                        side: const BorderSide(color: _brandingBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(ctx, building, vm),
                      icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.white),
                      label: const Text('삭제', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: _brandingBlue, size: 18),
          const SizedBox(width: 12),
          Text('$label  ', style: const TextStyle(color: _lightGrey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: _charcoal, fontSize: 13, fontWeight: FontWeight.w700),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Building building, BuildingViewModel vm) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('건물 삭제', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('"${building.buildingName}"를 삭제하시겠습니까?\n결함 이력이 있을 경우 삭제가 불가합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(_);
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await vm.deleteBuilding(building.id);
              if (!ok && mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('삭제 실패: 결함 이력을 먼저 삭제해주세요.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddBuildingSheet(BuildContext context, BuildingViewModel vm, {Building? editBuilding}) {
    final nameCtrl = TextEditingController(text: editBuilding?.buildingName ?? '');
    final locationCtrl = TextEditingController(text: editBuilding?.location ?? '');
    String? selectedDate = editBuilding?.completionDate;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: const BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    editBuilding == null ? '새 건물 등록' : '건물 정보 수정',
                    style: const TextStyle(color: _charcoal, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text('정확한 정보를 입력해주세요.', style: TextStyle(color: _lightGrey, fontSize: 12)),
                  const SizedBox(height: 24),
                  _buildFormField(
                    controller: nameCtrl,
                    label: '건물 이름',
                    hint: '예) 정보공학관',
                    icon: Icons.domain_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? '건물 이름을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    controller: locationCtrl,
                    label: '위치 (주소)',
                    hint: '예) 서울시 강남구 테헤란로 123',
                    icon: Icons.location_on_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? '위치를 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.light(primary: _brandingBlue),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _bgOffWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: _brandingBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDate ?? '완공일자 선택 (선택사항)',
                              style: TextStyle(
                                color: selectedDate != null ? _charcoal : _lightGrey,
                                fontSize: 14,
                                fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: _lightGrey, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final messenger = ScaffoldMessenger.of(context);
                        bool ok;
                        if (editBuilding == null) {
                          ok = await vm.addBuilding(nameCtrl.text.trim(), locationCtrl.text.trim(), selectedDate);
                        } else {
                          ok = await vm.updateBuilding(editBuilding.id, nameCtrl.text.trim(), locationCtrl.text.trim(), selectedDate);
                        }

                        if (mounted && ctx.mounted) {
                          Navigator.pop(ctx);
                          messenger.showSnackBar(SnackBar(
                            content: Text(ok ? (editBuilding == null ? '건물이 등록되었습니다.' : '건물 정보가 수정되었습니다.') : '처리에 실패했습니다. 권한을 확인해주세요.'),
                            backgroundColor: ok ? _green : _red,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandingBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        editBuilding == null ? '등록하기' : '수정 완료',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: _charcoal, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _brandingBlue, size: 20),
        filled: true,
        fillColor: _bgOffWhite,
        labelStyle: const TextStyle(color: _lightGrey, fontSize: 13),
        hintStyle: TextStyle(color: _lightGrey.withValues(alpha: 0.6), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brandingBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class BuildingMapWidget extends StatefulWidget {
  final String address;
  const BuildingMapWidget({super.key, required this.address});

  @override
  State<BuildingMapWidget> createState() => _BuildingMapWidgetState();
}

class _BuildingMapWidgetState extends State<BuildingMapWidget> {
  LatLng? _targetLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _geocodeAddress();
  }

  Future<void> _geocodeAddress() async {
    try {
      // 주소 문자열에서 좌표 추출 시도
      List<Location> locations = await locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        if (mounted) {
          setState(() {
            _targetLocation = LatLng(locations.first.latitude, locations.first.longitude);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // 에러 시에도 로딩 종료
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.bgOffWhite,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.brandingBlue),
        ),
      );
    }

    if (_targetLocation == null) {
      return Container(
        color: AppColors.bgOffWhite,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, color: AppColors.lightGrey, size: 32),
              SizedBox(height: 8),
              Text('지도를 불러올 수 없습니다.\n올바른 주소인지 확인해주세요.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.lightGrey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _targetLocation!,
            zoom: 15.0,
          ),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          markers: {
            Marker(
              markerId: const MarkerId('building_marker'),
              position: _targetLocation!,
              infoWindow: InfoWindow(
                title: '건물 위치',
                snippet: widget.address,
              ),
              onTap: () {
                // 클릭 시 말풍선(InfoWindow)과 함께 스낵바로도 주소 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('위치: ${widget.address}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.brandingBlue,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          },
        ),
        // 사용자에게 지도 클릭 유도 텍스트 오버레이
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('마커를 눌러 주소 확인', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
