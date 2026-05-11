import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class DeviceManagementView extends StatefulWidget {
  const DeviceManagementView({super.key});

  @override
  State<DeviceManagementView> createState() => _DeviceManagementViewState();
}

class _DeviceManagementViewState extends State<DeviceManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeviceViewModel>(context, listen: false).fetchDevices();
    });
  }

  // 화이트 미니멀 테마 색상 정의
  static const Color bgOffWhite = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textCharcoal = Color(0xFF1A1D21);
  static const Color textLightGrey = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color brandingBlue = Color(0xFF2563EB);
  static const Color redOffline = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgOffWhite,
      body: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Pretendard'),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header (화이트 테마)
              _buildPremiumHeader(),

              Expanded(
                child: Consumer<DeviceViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: brandingBlue, strokeWidth: 3),
                      );
                    }

                    final devices = viewModel.devices;
                    final onlineCount = devices.where((d) => d.isOnline).length;
                    final offlineCount = devices.length - onlineCount;

                    // 에러 상태 (리스트가 비어있을 때만)
                    if (viewModel.errorMessage != null && devices.isEmpty) {
                      return _buildErrorState(viewModel.errorMessage!);
                    }

                    return RefreshIndicator(
                      color: brandingBlue,
                      backgroundColor: cardWhite,
                      onRefresh: viewModel.fetchDevices,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Summary Dashboard
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildSummaryCard(
                                          '연결된 장치',
                                          '$onlineCount',
                                          '대',
                                          brandingBlue,
                                          true)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildSummaryCard(
                                          '전원 꺼짐',
                                          '$offlineCount',
                                          '대',
                                          redOffline,
                                          false)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // List Header
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Icon(Icons.wifi_tethering,
                                      color: brandingBlue, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '기기 목록',
                                    style: TextStyle(
                                        color: textCharcoal,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Device List or Empty State
                            if (devices.isEmpty)
                              SizedBox(
                                  height: 250,
                                  child: _buildEmptyState())
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Column(
                                  children: devices
                                      .map((d) => _buildPremiumDeviceCard(
                                          d, viewModel, context))
                                      .toList(),
                                ),
                              ),

                            const SizedBox(height: 32),

                            // Facility List Header
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Icon(Icons.build_circle_outlined,
                                      color: brandingBlue, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '시설물 리스트',
                                    style: TextStyle(
                                        color: textCharcoal,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Facility Cards
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                children: [
                                  _buildFacilityCard('본관', 85),
                                  _buildFacilityCard('수덕전', 60),
                                  _buildFacilityCard('효민갤러리', 100),
                                  _buildFacilityCard('정보공학관', 45),
                                ],
                              ),
                            ),

                            const SizedBox(height: 100), // FAB 여백
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Provider.of<AuthViewModel>(context).currentUser?.role != 'viewer' 
        ? FloatingActionButton(
            onPressed: () {
                _showAddDeviceModal(context);
              },
              backgroundColor: brandingBlue,
              elevation: 4, // 그림자
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null, // admin이 아닐 경우 null 반환
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: borderLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.settings_input_component_outlined,
                color: brandingBlue, size: 26),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('장치 및 시설물 관리',
                  style: TextStyle(
                      fontFamily: 'Pretendard',
                      color: textCharcoal,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String countValue, String unit,
      Color highlightColor, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? highlightColor.withValues(alpha: 0.3)
              : borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: isPrimary ? highlightColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: textLightGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                countValue,
                style: TextStyle(
                    color: highlightColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.0),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      color: highlightColor.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDeviceCard(Device device, DeviceViewModel viewModel, BuildContext context) {
    final String? userRole = Provider.of<AuthViewModel>(context, listen: false).currentUser?.role;
    final bool isOnline = device.isOnline;
    final Color statusColor = isOnline ? const Color(0xFF10B981) : redOffline; // 초록 or 빨강
    final String statusText = isOnline ? 'Online' : 'Offline';

    return Dismissible(
      key: Key(device.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: redOffline,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (userRole != 'admin' && userRole != 'super_admin') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('장치 삭제 권한이 없습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: redOffline,
            ),
          );
          return false;
        }
        bool confirmDelete = false;
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: borderLight)),
            title: const Text('장치 삭제', style: TextStyle(color: textCharcoal, fontWeight: FontWeight.bold)),
            content: Text('${device.deviceName}을(를) 시스템에서 영구적으로 삭제하시겠습니까?', 
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
                  backgroundColor: redOffline,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
        
        if (confirmDelete) {
          final success = await viewModel.deleteDevice(device.id);
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage ?? '장치 삭제에 실패했습니다.'), backgroundColor: redOffline),
            );
            viewModel.clearError();
            return false;
          } else if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('장치가 성공적으로 삭제되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: brandingBlue),
            );
            return true;
          }
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderLight, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Status left indicator bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(color: statusColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            device.deviceName,
                            style: const TextStyle(
                                color: textCharcoal,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(statusText,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Row 2: Info & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Sub-info (Location & MAC)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place_outlined,
                                    color: textLightGrey, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '위치: ${device.location}',
                                  style: const TextStyle(
                                      color: textLightGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.memory_outlined,
                                    color: textLightGrey, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'MAC: ${device.macAddress}',
                                  style: const TextStyle(
                                      color: textLightGrey,
                                      fontSize: 13,
                                      fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Actions (권한별 분기: 최고관리자/현장관리자 제어 가능)
                        Row(
                          children: [
                            if (userRole != 'viewer') ...[
                              _buildIconButton(
                                  Icons.edit_outlined, brandingBlue, () {
                                _showEditDeviceModal(context, device);
                              }),
                              const SizedBox(width: 8),
                              _buildIconButton(Icons.delete_outline_rounded,
                                  redOffline, () {
                                _showDeleteConfirmDialog(context, device, viewModel);
                              }),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.1),
        hoverColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.05),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandingBlue.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandingBlue.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: brandingBlue, size: 50),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '등록된 기기가 없어요!',
            style: TextStyle(
                color: textCharcoal,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '현장에 배치된 AI 단말기가 없습니다.\n아래의 + 버튼을 눌러 새 기기를 등록해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textLightGrey,
                fontSize: 14,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: redOffline.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: redOffline, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            '오류가 발생했습니다',
            style: TextStyle(
                color: textCharcoal,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: textLightGrey, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(String buildingName, int progressPct) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                buildingName,
                style: const TextStyle(
                    color: textCharcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: brandingBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '안전 점검 진행률',
                  style: TextStyle(
                      color: brandingBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '진행 상태',
                style: TextStyle(
                    color: textLightGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '$progressPct%',
                style: const TextStyle(
                    color: brandingBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressPct / 100.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(brandingBlue),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============== 신규 장치 등록 모달 UI ==============
  void _showAddDeviceModal(BuildContext context) {
    final macController = TextEditingController();
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '신규 AI 단말 등록',
                      style: TextStyle(
                          color: textCharcoal,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textLightGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModalTextField(
                    label: 'MAC 주소',
                    hint: 'ex) 00:1A:2B:3C:4D:5E',
                    controller: macController),
                const SizedBox(height: 16),
                _buildModalTextField(
                    label: '디바이스 이름',
                    hint: 'ex) AI 안전 단말기 04호',
                    controller: nameController),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return _buildModalDropdownField(
                      label: '섹션',
                      value: locationController.text.isEmpty ? '본관' : locationController.text,
                      items: ['본관', '수덕전', '효민갤러리', '정보공학관'],
                      onChanged: (val) {
                        setState(() {
                          locationController.text = val!;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      String mac = macController.text.trim();
                      String name = nameController.text.trim();
                      String section = locationController.text.trim();

                      void showError(String msg) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).size.height * 0.8,
                              left: 20,
                              right: 20,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(msg,
                                        style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            backgroundColor: redOffline,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      if (mac.isEmpty || name.isEmpty || section.isEmpty) {
                        showError('모든 항목을 입력해주세요.');
                        return;
                      }

                      if (!RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(mac)) {
                        showError('MAC 주소 형식이 올바르지 않습니다.');
                        return;
                      }

                      if (!RegExp(r'^[a-zA-Z0-9가-힣\s]+$').hasMatch(name)) {
                        showError('디바이스 이름에 특수기호를 사용할 수 없습니다.');
                        return;
                      }

                      if (!RegExp(r'^[a-zA-Z가-힣\s]+$').hasMatch(section)) {
                        showError('섹션에는 오직 글자(한/영)만 입력 가능합니다.');
                        return;
                      }

                      final deviceViewModel = Provider.of<DeviceViewModel>(context, listen: false);
                      final isDuplicateMac = deviceViewModel.devices.any((d) => d.macAddress.toUpperCase() == mac.toUpperCase());
                      final isDuplicateName = deviceViewModel.devices.any((d) => d.deviceName == name);
                      final isDuplicateLocation = deviceViewModel.devices.any((d) => d.location == section);

                      if (isDuplicateMac) {
                        showError('이미 등록된 MAC 주소입니다.');
                        return;
                      }
                      if (isDuplicateName) {
                        showError('이미 사용 중인 기기 이름입니다.');
                        return;
                      }
                      if (isDuplicateLocation) {
                        showError('해당 위치에는 이미 기기가 등록되어 있습니다.');
                        return;
                      }

                      final success = await ApiService()
                          .addJetsonDevice(mac, name, section);

                      if (!success) {
                        showError('서버 오류: 장치를 DB에 등록하지 못했습니다.');
                        return;
                      }

                      if (!context.mounted) return;
                      Provider.of<DeviceViewModel>(context, listen: false).fetchDevices();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '새로운 AI 단말이 성공적으로 등록되었습니다!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: brandingBlue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandingBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('장치 추가하기',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDeviceModal(BuildContext context, Device device) {
    final macController = TextEditingController(text: device.macAddress);
    final nameController = TextEditingController(text: device.deviceName);
    final locationController = TextEditingController(text: device.location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI 단말 정보 수정',
                      style: TextStyle(
                          color: textCharcoal,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textLightGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModalTextField(
                    label: 'MAC 주소',
                    hint: 'ex) 00:1A:2B:3C:4D:5E',
                    controller: macController),
                const SizedBox(height: 16),
                _buildModalTextField(
                    label: '디바이스 이름',
                    hint: 'ex) AI 안전 단말기 04호',
                    controller: nameController),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    // 기기의 초기 위치가 목록에 없을 경우를 대비한 방어 코드
                    String initialValue = locationController.text;
                    List<String> options = ['본관', '수덕전', '효민갤러리', '정보공학관'];
                    if (initialValue.isNotEmpty && !options.contains(initialValue)) {
                      options.add(initialValue);
                    } else if (initialValue.isEmpty) {
                      initialValue = '본관';
                    }

                    return _buildModalDropdownField(
                      label: '섹션',
                      value: initialValue,
                      items: options,
                      onChanged: (val) {
                        setState(() {
                          locationController.text = val!;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      String mac = macController.text.trim();
                      String name = nameController.text.trim();
                      String section = locationController.text.trim();

                      void showError(String msg) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              ],
                            ),
                            backgroundColor: redOffline,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                                bottom: MediaQuery.of(context).size.height * 0.8,
                                left: 20, right: 20),
                          ),
                        );
                      }

                      if (!RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(mac)) {
                        showError('MAC 주소 형식이 올바르지 않습니다.');
                        return;
                      }

                      if (!RegExp(r'^[a-zA-Z0-9가-힣\s]+$').hasMatch(name)) {
                        showError('디바이스 이름에 특수기호를 사용할 수 없습니다.');
                        return;
                      }

                      if (!RegExp(r'^[a-zA-Z가-힣\s]+$').hasMatch(section)) {
                        showError('위치는 글자(한/영)만 입력 가능합니다.');
                        return;
                      }

                      final success = await ApiService().updateJetsonDevice(device.id, mac, name, section);

                      if (!success) {
                        showError('서버 오류: 장치 정보를 수정하지 못했습니다.');
                        return;
                      }

                      if (!context.mounted) return;
                      Provider.of<DeviceViewModel>(context, listen: false).fetchDevices();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('단말기 정보가 성공적으로 수정되었습니다!', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          backgroundColor: brandingBlue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandingBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('수정 완료',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalTextField(
      {required String label,
      required String hint,
      required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: textCharcoal,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: textCharcoal, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textLightGrey),
            filled: true,
            fillColor: bgOffWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderLight, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderLight, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: brandingBlue, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildModalDropdownField({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: textCharcoal,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          icon: const Icon(Icons.arrow_drop_down, color: textLightGrey),
          style: const TextStyle(color: textCharcoal, fontSize: 15, fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: bgOffWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderLight, width: 1)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderLight, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brandingBlue, width: 2)),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext parentContext, Device device, DeviceViewModel viewModel) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: borderLight)),
        title: const Text('장치 삭제', style: TextStyle(color: textCharcoal, fontWeight: FontWeight.bold)),
        content: Text('${device.deviceName}을(를) 시스템에서 영구적으로 삭제하시겠습니까?', 
          style: const TextStyle(color: textLightGrey, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: textLightGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await viewModel.deleteDevice(device.id);
              
              if (!success && parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.errorMessage ?? '장치 삭제에 실패했습니다.'),
                    backgroundColor: redOffline,
                  ),
                );
                viewModel.clearError();
              } else if (success && parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('장치가 성공적으로 삭제되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: brandingBlue,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redOffline,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
