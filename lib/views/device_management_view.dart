import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/device_viewmodel.dart';
import '../models/device.dart';

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
                        child: CircularProgressIndicator(color: cyanAccent, strokeWidth: 3),
                      );
                    }

                    if (viewModel.errorMessage != null) {
                      return _buildErrorState(viewModel.errorMessage!, redOffline);
                    }

                    final devices = viewModel.devices;
                    final onlineCount = devices.where((d) => d.isOnline).length;
                    final offlineCount = devices.length - onlineCount;

                    return RefreshIndicator(
                      color: cyanAccent,
                      backgroundColor: navyCard,
                      onRefresh: viewModel.fetchDevices,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Summary Dashboard
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(child: _buildSummaryCard('연결된 장치', '$onlineCount', '대', cyanAccent, true)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSummaryCard('점검 필요', '$offlineCount', '대', redOffline, false)),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            // List Header
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Icon(Icons.wifi_tethering, color: cyanAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Jetson 기기',
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: 18, 
                                      fontWeight: FontWeight.w700, 
                                      letterSpacing: 0.5
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Device List or Empty State
                            if (devices.isEmpty)
                              SizedBox(height: 250, child: _buildEmptyState(cyanAccent))
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Column(
                                  children: devices.map((d) => _buildPremiumDeviceCard(d, cyanAccent, redOffline, viewModel)).toList(),
                                ),
                              ),
                            
                            const SizedBox(height: 32),
                            
                            // Facility List Header
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Icon(Icons.build_circle_outlined, color: cyanAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '시설물 리스트',
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: 18, 
                                      fontWeight: FontWeight.w700, 
                                      letterSpacing: 0.5
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Facility Cards
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<DeviceViewModel>(context, listen: false).mapsToAddDevice(context);
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
            ]
          ),
          child: const Icon(Icons.add, color: Color(0xFF0F172A), size: 30),
        ),
      ),
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
                  border: Border.all(color: cyanAccent.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: cyanAccent.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.settings_input_component_outlined, color: cyanAccent, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('장치 및 시설물 관리', 
                    style: TextStyle(fontFamily: 'Pretendard', color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 2),
                  Text('DEVICE INFRASTRUCTURE', 
                    style: TextStyle(fontFamily: 'Pretendard', color: cyanAccent.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 28),
            splashRadius: 24,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String countValue, String unit, Color highlightColor, bool isGlow) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGlow ? highlightColor.withValues(alpha: 0.5) : const Color(0xFF334155),
          width: 1.5,
        ),
        boxShadow: isGlow ? [
          BoxShadow(
            color: highlightColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4)
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                countValue,
                style: TextStyle(color: highlightColor, fontSize: 32, fontWeight: FontWeight.w800, height: 1.0),
              ),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: highlightColor.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDeviceCard(Device device, Color cyanAccent, Color redOffline, DeviceViewModel viewModel) {
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
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1),
                  ]
                ),
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
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Glowing Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                                  BoxShadow(color: statusColor.withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 1),
                                ]
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
                              const Icon(Icons.place_outlined, color: Color(0xFF94A3B8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '위치: ${device.location}',
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.memory_outlined, color: Color(0xFF94A3B8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'MAC: ${device.macAddress}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Actions
                      Row(
                        children: [
                          _buildLineArtIconButton(Icons.edit_outlined, 'Edit', cyanAccent, () {}),
                          const SizedBox(width: 12),
                          _buildLineArtIconButton(Icons.delete_outline_rounded, 'Delete', Colors.white70, () {
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

  Widget _buildLineArtIconButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
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
                    BoxShadow(color: cyanAccent.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
                  ]
                ),
              ),
              Icon(Icons.precision_manufacturing_outlined, color: cyanAccent.withValues(alpha: 0.8), size: 64),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'NO DEVICES FOUND',
            style: TextStyle(fontFamily: 'Pretendard', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),
          const Text(
            '시스템에 등록된 장치가 없습니다.\n하단의 버튼을 눌러 새 장치를 등록하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Pretendard', color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
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
          Icon(Icons.error_outline_rounded, color: redOffline.withValues(alpha: 0.8), size: 64),
          const SizedBox(height: 24),
          const Text(
            'SYSTEM ERROR',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(String buildingName, int progressPct, Color cyanAccent) {
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
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
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
                  style: TextStyle(color: cyanAccent, fontSize: 11, fontWeight: FontWeight.w600),
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
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '$progressPct%',
                style: TextStyle(color: cyanAccent, fontSize: 16, fontWeight: FontWeight.w800),
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
}


