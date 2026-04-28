import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../viewmodels/auth_viewmodel.dart'; // 추가됨

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

  @override
  Widget build(BuildContext context) {
    const Color navyBase = Color(0xFF0F172A);
    const Color navyCard = Color(0xFF1E293B);
    const Color cyanAccent = Color(0xFF06B6D4);
    const Color redOffline = Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: navyBase,
      body: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Pretendard'),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              _buildPremiumHeader(cyanAccent),

              Expanded(
                child: Consumer<DeviceViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: cyanAccent, strokeWidth: 3),
                      );
                    }

                    if (viewModel.errorMessage != null) {
                      return _buildErrorState(
                          viewModel.errorMessage!, redOffline);
                    }

                    final devices = viewModel.devices;
                    final onlineCount = devices.where((d) => d.isOnline).length;
                    final offlineCount = devices.length - onlineCount;

                    return RefreshIndicator(
                      color: cyanAccent,
                      backgroundColor: navyCard,
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
                                          cyanAccent,
                                          true)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildSummaryCard(
                                          '점검 필요',
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
                                      color: cyanAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Jetson 기기',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Device List or Empty State
                            if (devices.isEmpty)
                              SizedBox(
                                  height: 250,
                                  child: _buildEmptyState(cyanAccent))
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Column(
                                  children: devices
                                      .map((d) => _buildPremiumDeviceCard(
                                          d, cyanAccent, redOffline, viewModel))
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
                                      color: cyanAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '시설물 리스트',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5),
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
                                  _buildFacilityCard('본관', 85, cyanAccent),
                                  _buildFacilityCard('수덕전', 60, cyanAccent),
                                  _buildFacilityCard('효민갤러리', 100, cyanAccent),
                                  _buildFacilityCard('정보공학관', 45, cyanAccent),
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
      floatingActionButton: Provider.of<AuthViewModel>(context)
                  .currentUser
                  ?.role ==
              'admin'
          ? FloatingActionButton(
              onPressed: () {
                _showAddDeviceModal(context);
              },
              backgroundColor: const Color(0xFF06B6D4),
              elevation: 0,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF06B6D4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]),
                child:
                    const Icon(Icons.add, color: Color(0xFF0F172A), size: 30),
              ),
            )
          : null, // admin이 아닐 경우 null 반환
    );
  }

  Widget _buildPremiumHeader(Color cyanAccent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cyanAccent.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: cyanAccent.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.settings_input_component_outlined,
                    color: cyanAccent, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('장치 및 시설물 관리',
                      style: TextStyle(
                          fontFamily: 'Pretendard',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('DEVICE INFRASTRUCTURE',
                      style: TextStyle(
                          fontFamily: 'Pretendard',
                          color: cyanAccent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white70, size: 28),
            splashRadius: 24,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String countValue, String unit,
      Color highlightColor, bool isGlow) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGlow
              ? highlightColor.withValues(alpha: 0.5)
              : const Color(0xFF334155),
          width: 1.5,
        ),
        boxShadow: isGlow
            ? [
                BoxShadow(
                    color: highlightColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
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
                    fontWeight: FontWeight.w800,
                    height: 1.0),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      color: highlightColor.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDeviceCard(Device device, Color cyanAccent,
      Color redOffline, DeviceViewModel viewModel) {
    final bool isOnline = device.isOnline;
    final Color statusColor = isOnline ? cyanAccent : redOffline;
    final String statusText = isOnline ? 'Online' : 'Offline';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
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
                decoration: BoxDecoration(color: statusColor, boxShadow: [
                  BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1),
                ]),
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Glowing Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            statusColor.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1),
                                  ]),
                            ),
                            const SizedBox(width: 6),
                            Text(statusText,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
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
                                  color: Color(0xFF94A3B8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '위치: ${device.location}',
                                style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.memory_outlined,
                                  color: Color(0xFF94A3B8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'MAC: ${device.macAddress}',
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Actions
                      Row(
                        children: [
                          _buildLineArtIconButton(
                              Icons.edit_outlined, 'Edit', cyanAccent, () {}),
                          const SizedBox(width: 12),
                          _buildLineArtIconButton(Icons.delete_outline_rounded,
                              'Delete', Colors.white70, () {
                            viewModel.deleteDevice(device.id);
                          }),
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
    );
  }

  Widget _buildLineArtIconButton(
      IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.2),
        hoverColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
            color: const Color(0xFF0F172A).withValues(alpha: 0.5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cyanAccent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cyanAccent.withValues(alpha: 0.05),
                    boxShadow: [
                      BoxShadow(
                          color: cyanAccent.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10),
                    ]),
              ),
              Icon(Icons.precision_manufacturing_outlined,
                  color: cyanAccent.withValues(alpha: 0.8), size: 64),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'NO DEVICES FOUND',
            style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),
          const Text(
            '시스템에 등록된 장치가 없습니다.\n하단의 버튼을 눌러 새 장치를 등록하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Pretendard',
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, Color redOffline) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: redOffline.withValues(alpha: 0.8), size: 64),
          const SizedBox(height: 24),
          const Text(
            'SYSTEM ERROR',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(
      String buildingName, int progressPct, Color cyanAccent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
            blurRadius: 12,
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '안전 점검 진행률',
                  style: TextStyle(
                      color: cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '진행 상태',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '$progressPct%',
                style: TextStyle(
                    color: cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct / 100.0,
              minHeight: 8,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ============== [추가] 신규 장치 등록 모달 UI ==============
  void _showAddDeviceModal(BuildContext context) {
    final macController = TextEditingController();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    const cyanAccent = Color(0xFF06B6D4);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 올라올 때 모달이 밀려 올라가도록 허용
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 높이만큼 여백
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                  top: BorderSide(
                      color: Color(0xFF1E293B), width: 1)), // 상단 옅은 보더
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
                          color: cyanAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
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
                _buildModalTextField(
                    label: '섹션',
                    hint: 'ex) 정보공학관 로비',
                    controller: locationController),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      String mac = macController.text.trim();
                      String name = nameController.text.trim();
                      String section = locationController.text.trim();

                      void showError(String msg) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).size.height *
                                  0.75, // 모달과 키보드에 안 가리도록 최상단으로 위치 이동
                              left: 16,
                              right: 16,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(msg,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      if (mac.isEmpty || name.isEmpty || section.isEmpty) {
                        showError('모든 항목을 입력해주세요.');
                        return;
                      }

                      // 1. MAC 주소 검사 (예: 00:1A:2B:3C:4D:5E)
                      if (!RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$')
                          .hasMatch(mac)) {
                        showError('MAC 주소 형식이 올바르지 않습니다.');
                        return;
                      }

                      // 2. 이름 검사 (특수기호 X. 영문, 한글, 숫자, 띄어쓰기만 허용)
                      if (!RegExp(r'^[a-zA-Z0-9가-힣\s]+$').hasMatch(name)) {
                        showError('디바이스 이름에 특수기호를 사용할 수 없습니다.');
                        return;
                      }

                      // 3. 섹션 검사 (글자만 허용. 숫자 및 특수기호 차단)
                      if (!RegExp(r'^[a-zA-Z가-힣\s]+$').hasMatch(section)) {
                        showError('섹션에는 오직 글자(한/영)만 입력 가능합니다.');
                        return;
                      }

                      // 입력값 검증을 넘어갔다면 백엔드로 API 전송 시작!
                      final success = await ApiService()
                          .addJetsonDevice(mac, name, section);

                      if (!success) {
                        showError('서버 오류: 장치를 DB에 등록하지 못했습니다.');
                        return; // 실패 시 모달을 닫지 않고 에러 띄움
                      }

                      // 백엔드 DB 저장 성공 시, 프론트엔드 화면(DeviceViewModel) 리스트에도 즉시 꽂아넣어서 새로고침 트리거!
                      Provider.of<DeviceViewModel>(context, listen: false)
                          .appendNewDevice(mac, name, section);

                      // 모두 통과했을 경우 성공 처리
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('새로운 AI 단말이 jetson_devices DB에 등록되었습니다!',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          backgroundColor: cyanAccent,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyanAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('장치 추가하기',
                        style: TextStyle(
                            color: Color(0xFF0F172A),
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

  // 모달 내부 입력창 통일 위젯
  Widget _buildModalTextField(
      {required String label,
      required String hint,
      required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF06B6D4), width: 1)),
          ),
        ),
      ],
    );
  }
}
