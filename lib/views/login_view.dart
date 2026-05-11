import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_colors.dart';
import 'signup_view.dart';
import 'find_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // ─── 색상 토큰: AppColors 참조 ──────────────────────────
  static const Color _bgOffWhite   = AppColors.bgOffWhite;
  static const Color _cardWhite    = AppColors.cardWhite;
  static const Color _charcoal     = AppColors.charcoal;
  static const Color _lightGrey    = AppColors.lightGrey;
  static const Color _brandingBlue = AppColors.brandingBlue;
  static const Color _borderLight  = AppColors.borderLight;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isGeneralUser = true;
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
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bgOffWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 상단 타이틀 영역
                _buildHeader(),
                const SizedBox(height: 32),
                
                // 2. 메인 화이트 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사용자 유형 선택 (General / Admin)
                      Row(
                        children: [
                          Expanded(child: _typeCard(true, '일반 사용자', 'General', Icons.person_outline_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _typeCard(false, '현장 관리자', 'Admin', Icons.admin_panel_settings_outlined)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('아이디', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _charcoal)),
                      const SizedBox(height: 10),
                      _inputField(
                        controller: _emailController,
                        hint: 'example@email.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      
                      const Text('비밀번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _charcoal)),
                      const SizedBox(height: 10),
                      _passwordField(),
                      
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FindPasswordView()));
                          },
                          style: TextButton.styleFrom(foregroundColor: _lightGrey),
                          child: const Text('비밀번호 찾기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 로그인 버튼 (5번째 사진 스타일: Solid Blue + Arrow)
                      isLoading
                          ? const Center(child: CircularProgressIndicator(color: _brandingBlue))
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _handleLogin,
                                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                                label: const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandingBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            
                      const SizedBox(height: 24),
                      
                      // 구분선
                      const Row(
                        children: [
                          Expanded(child: Divider(color: _borderLight)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('시스템 접근 권한이 없으신가요?', style: TextStyle(color: _lightGrey, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: _borderLight)),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 회원가입 버튼
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupView()));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _lightGrey,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('회원가입', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: _brandingBlue,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _brandingBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.security_rounded, size: 42, color: Colors.white),
        ),
        const SizedBox(height: 28),
        const Text(
          'SOC 안전진단 시스템',
          style: TextStyle(
            color: _charcoal,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '로그인하여 시스템에 접근하세요.',
          style: TextStyle(
            color: _lightGrey,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _typeCard(bool isGeneral, String title, String subtitle, IconData icon) {
    bool isSelected = _isGeneralUser == isGeneral;
    return GestureDetector(
      onTap: () => setState(() => _isGeneralUser = isGeneral),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? _brandingBlue.withValues(alpha: 0.05) : _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _brandingBlue : _borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _brandingBlue.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? _brandingBlue : _lightGrey),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? _brandingBlue : _charcoal),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: isSelected ? _brandingBlue.withValues(alpha: 0.8) : _lightGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _charcoal),
      cursorColor: _brandingBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _lightGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: _lightGrey, size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brandingBlue, width: 1.5)),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: _charcoal),
      cursorColor: _brandingBlue,
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: _lightGrey, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _lightGrey, size: 22),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _lightGrey, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brandingBlue, width: 1.5)),
      ),
    );
  }
}
