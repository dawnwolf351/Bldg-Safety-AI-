import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'signup_view.dart';
import 'find_password_view.dart';

// 사용자 로그인을 처리하는 View (화면) 클래스입니다.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 사용자 유형 선택 라디오 상태 (UI 전용)
  bool _isGeneralUser = true;
  // 비밀번호 표시/숨김 토글 상태
  bool _obscurePassword = true;

  void _handleLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    final selectedRole = _isGeneralUser ? 'viewer' : 'admin';
    String? errorMessage = await authViewModel.login(
      _emailController.text, 
      _passwordController.text,
      role: selectedRole,
    );

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthViewModel의 상태 변화(예: 로딩 중)를 구독합니다.
    final isLoading = context.watch<AuthViewModel>().isLoading;
    
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
                      child: const Icon(Icons.memory, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '건물 구조 안전 진단',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Drone-based Building Diagnosis System',
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
                        Row(
                          children: [
                            Expanded(child: _buildTypeCard(true, '일반 사용자', 'General User', Icons.person_outline, cyanColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTypeCard(false, '현장 관리자', 'Field Admin', Icons.shield_outlined, cyanColor)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        const Text('이메일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next, // 엔터 누르면 비밀번호 칸으로 이동
                          decoration: _inputDecoration(
                            hint: 'example@email.com',
                            prefixIcon: Icons.mail_outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        const Text('비밀번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done, // 엔터 누르면 완료(로그인)
                          onSubmitted: (_) => _handleLogin(), // 엔터 입력 시 로그인 함수 실행
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FindPasswordView()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: cyanColor.withValues(alpha: 0.8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '비밀번호를 잊으셨나요?', 
                              style: TextStyle(
                                color: cyanColor.withValues(alpha: 0.9), 
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // 로그인 버튼
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navyColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupView()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: '계정이 없으신가요? ',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: '회원가입',
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
  Widget _buildTypeCard(bool isGeneral, String title, String subtitle, IconData icon, Color activeColor) {
    bool isSelected = _isGeneralUser == isGeneral;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isGeneralUser = isGeneral;
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

  // 공통 텍스트 필드 디자인
  InputDecoration _inputDecoration({required String hint, required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50], // 연한 회색 배경
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
    );
  }
}
