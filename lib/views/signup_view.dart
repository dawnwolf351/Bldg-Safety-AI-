import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  // [로직 보존]: 기존에 연결된 변수명 완벽 유지
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 현장 관리자용 시각적 필드 (Auth 로직 무결성을 위해 UI용으로 추가)
  final TextEditingController _adminCodeController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  // [로직 보존]: 토글 버튼 상태 관리 (0: 일반 사용자, 1: 현장 관리자) 동일 유지
  final List<bool> _selections = [true, false];
  String get _selectedRole => _selections[0] ? 'viewer' : 'admin';

  // 비밀번호 표시/숨김 토글
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleSignUp() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // [로직 보존]: 뷰모델의 signUp 함수 호출 (새로운 항목 추가)
    final errorMessage = await authViewModel.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: _selectedRole,
      phone: _phoneController.text,
      adminCode: _adminCodeController.text,
      company: _companyController.text,
    );

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되어 자동으로 로그인되었습니다!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), 
          backgroundColor: Color(0xFF00E5FF),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;
    
    // 로그인 화면과 동일한 테마 컬러
    const Color navyColor = Color(0xFF0F172A);
    const Color cyanColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: navyColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A101D), Color(0xFF152238)], // 다크 네이비 그라데이션
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. 상단 타이틀 영역 (Headers)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cyanColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cyanColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '신규 계정 생성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create your new account',
                      style: TextStyle(
                        color: cyanColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. 하단 둥근 화이트 폼 (Bottom Sheet Style)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '사용자 유형 선택',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // [로직 보존]: 기존 _selections 논리를 활용한 맞춤 UI 토글
                        Row(
                          children: [
                            Expanded(child: _buildTypeCard(0, '일반 사용자', 'General User', Icons.person_outline, cyanColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTypeCard(1, '현장 관리자', 'Field Admin', Icons.shield_outlined, cyanColor)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // [조건부 렌더링]: 상태에 따라 관리자 박스 표시 
                        if (!_selections[0]) ...[
                          // --- 현장 관리자 시 표시되는 인증 박스 ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cyanColor.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cyanColor.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('관리자 인증 코드', color: Colors.teal[800]),
                                _buildInputField(
                                  controller: _adminCodeController, 
                                  hint: '인증 코드 입력', 
                                  icon: Icons.key_outlined,
                                  isHighlighted: true,
                                ),
                                const SizedBox(height: 16),
                                _buildLabel('소속 기관', color: Colors.teal[800]),
                                _buildInputField(
                                  controller: _companyController, 
                                  hint: '소속 회사 또는 기관명', 
                                  icon: Icons.business_outlined,
                                  isHighlighted: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // 공통 이름 필드
                        _buildLabel('이름'),
                        _buildInputField(
                          controller: _nameController, 
                          hint: '홍길동', 
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),

                        // 공통 이메일 및 비밀번호 필드
                        _buildLabel('이메일'),
                        _buildInputField(
                          controller: _emailController, 
                          hint: 'example@email.com', 
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('전화번호'),
                        _buildInputField(
                          controller: _phoneController, 
                          hint: '010-0000-0000', 
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('비밀번호'),
                        _buildPasswordField(
                          controller: _passwordController,
                          hint: '••••••••',
                          isConfirm: false,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('비밀번호 확인'),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          hint: '••••••••',
                          isConfirm: true,
                        ),
                        const SizedBox(height: 32),
                        
                        // 회원가입 버튼
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navyColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('가입 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context); // 로그인 화면으로 돌아가기
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: '이미 계정이 있나요? ',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: '로그인',
                                    style: TextStyle(color: cyanColor.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // 하단 스크롤 여백
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 사용자 유형 선택 카드 위젯
  Widget _buildTypeCard(int index, String title, String subtitle, IconData icon, Color activeColor) {
    bool isSelected = _selections[index];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          for (int i = 0; i < _selections.length; i++) {
            _selections[i] = i == index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? activeColor : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? activeColor.withValues(alpha: 0.8) : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
    );
  }

  // 공통 및 하이라이트 폼 컨트롤러 빌더
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isHighlighted = false,
    TextInputType? keyboardType,
  }) {
    const Color cyanColor = Color(0xFF00E5FF);
    final baseBorderColor = isHighlighted ? cyanColor.withValues(alpha: 0.4) : Colors.grey[200]!;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: isHighlighted ? cyanColor : Colors.grey[400], size: 22),
        filled: true,
        fillColor: isHighlighted ? Colors.white : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseBorderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cyanColor, width: 1.5),
        ),
      ),
    );
  }

  // 비밀번호 입력 폼 전용 (눈 아이콘 포함)
  Widget _buildPasswordField({required TextEditingController controller, required String hint, required bool isConfirm}) {
    bool obscure = isConfirm ? _obscureConfirmPassword : _obscurePassword;

    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
      ),
    );
  }
}
