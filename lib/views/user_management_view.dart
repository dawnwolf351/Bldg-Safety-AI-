import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../models/user.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  @override
  void initState() {
    super.initState();
    // 화면 로딩 시 유저 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().fetchUsers();
    });
  }

  // 직급 변경 다이얼로그
  void _showRoleChangeDialog(User user) {
    String selectedRole = user.roleName ?? 'ROLE_USER';
    if (selectedRole == 'ROLE_SUPERADMIN') {
      selectedRole = 'ROLE_ADMIN'; // 예외 안전장치: 최고관리자는 일반관리자로 선택되도록 폴백
    }
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<UserViewModel>();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('사용자 권한 변경', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.name} (${user.email})', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('새로운 직급 선택:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'ROLE_USER', child: Text('일반 사용자 (ROLE_USER)')),
                      DropdownMenuItem(value: 'ROLE_ADMIN', child: Text('관리자 (ROLE_ADMIN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await viewModel.updateUser(user.id, roleName: selectedRole);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success ? '직급이 성공적으로 변경되었습니다.' : '사용자 권한 변경에 대한 권한이 존재하지 않습니다. (최고관리자 권한 필요)'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('변경 적용', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // 사용자 삭제 확인 다이얼로그
  void _showDeleteDialog(User user) {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<UserViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('사용자 계정 삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('정말로 ${user.name}(${user.email}) 계정을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await viewModel.deleteUser(user.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? '사용자 계정이 삭제되었습니다.' : '사용자 삭제에 대한 권한이 존재하지 않습니다. (최고관리자 권한 필요)'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('영구 삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 관리자용 사용자 등록 다이얼로그
  void _showRegisterDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<UserViewModel>();
    
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'ROLE_USER';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('새 사용자 계정 등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(labelText: '이메일', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pwCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: '비밀번호', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: '이름', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    const Text('직급 선택:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'ROLE_USER', child: Text('일반 사용자 (ROLE_USER)')),
                        DropdownMenuItem(value: 'ROLE_ADMIN', child: Text('관리자 (ROLE_ADMIN)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (emailCtrl.text.isEmpty || pwCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.'), backgroundColor: Colors.orange));
                      return;
                    }
                    Navigator.pop(ctx);
                    final success = await viewModel.registerUserAsAdmin(
                      email: emailCtrl.text.trim(),
                      password: pwCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      roleName: selectedRole,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success ? '새 사용자가 성공적으로 등록되었습니다.' : '사용자 등록에 대한 권한이 존재하지 않습니다. (혹은 중복 이메일)'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('계정 생성', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // 권한별 한글 설명 라벨 반환 헬퍼 메서드
  String _getRoleKoreanLabel(String role) {
    if (role == 'ROLE_SUPERADMIN' || role == 'ROLE_SUPER_ADMIN') {
      return '(최고 관리자)';
    } else if (role == 'ROLE_ADMIN') {
      return '(현장 관리자)';
    } else if (role == 'ROLE_USER') {
      return '(일반 사용자)';
    }
    return '(일반 사용자)';
  }

  // 권한별 영문 표기 깔끔화 헬퍼 메서드 (UI 표시용)
  String _getRoleDisplayLabel(String role) {
    String display = role.replaceAll('ROLE_', '');
    if (display == 'SUPERADMIN') {
      display = 'SUPER ADMIN';
    }
    return display.replaceAll('_', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 화이트/라이트그레이 배경
      appBar: AppBar(
        title: const Text('사용자 계정 관리', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Consumer<UserViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('목록을 불러올 수 없습니다.\n${viewModel.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchUsers(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final users = viewModel.users;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '시스템 사용자 목록',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showRegisterDialog,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('새 사용자 등록'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), // Blue 600
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 등록된 총 ${users.length}명의 사용자를 관리할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        columns: const [
                          DataColumn(label: Text('이름')),
                          DataColumn(label: Text('이메일')),
                          DataColumn(label: Text('직급 (권한)')),
                          DataColumn(label: Text('가입일')),
                          DataColumn(label: Text('관리 기능')),
                        ],
                        rows: users.map((user) {
                          // 직급 배지 색상 결정
                          Color badgeColor = Colors.grey;
                          if (user.level == 1 || user.roleName == 'ROLE_SUPERADMIN' || user.roleName == 'ROLE_SUPER_ADMIN') {
                            badgeColor = Colors.purple;
                          } else if (user.level == 2 || user.roleName == 'ROLE_ADMIN') {
                            badgeColor = Colors.blue;
                          } else {
                            badgeColor = Colors.green;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      child: Text(user.name.isNotEmpty ? user.name[0] : 'U', style: const TextStyle(color: Color(0xFF475569))),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              DataCell(Text(user.email, style: const TextStyle(color: Color(0xFF64748B)))),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _getRoleDisplayLabel(user.roleName ?? user.role),
                                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getRoleKoreanLabel(user.roleName ?? user.role),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(user.createdAt?.split('T').first ?? '정보 없음', style: const TextStyle(fontSize: 13))),
                              DataCell(
                                (user.level == 1 || user.roleName == 'ROLE_SUPERADMIN')
                                    ? const Text('변경 불가 (최고 관리자)', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic))
                                    : Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _showRoleChangeDialog(user),
                                            icon: const Icon(Icons.manage_accounts, size: 16),
                                            label: const Text('권한 수정'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF0F172A),
                                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _showDeleteDialog(user),
                                            icon: const Icon(Icons.delete_outline),
                                            color: Colors.red[400],
                                            tooltip: '계정 삭제',
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
