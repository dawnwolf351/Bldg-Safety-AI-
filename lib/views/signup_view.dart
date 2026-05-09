import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../theme/app_colors.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  // ─── 색상 토큰: AppColors 참조 ──────────────────────────
  static const Color _bgOffWhite   = AppColors.bgOffWhite;
  static const Color _cardWhite    = AppColors.cardWhite;
  static const Color _charcoal     = AppColors.charcoal;
  static const Color _lightGrey    = AppColors.lightGrey;
  static const Color _brandingBlue = AppColors.brandingBlue;
  static const Color _borderLight  = AppColors.borderLight;

  // ─── 기존 로직: 컨트롤러 & 상태 (완벽 보존) ─────────────────
  final TextEditingController _nameController            = TextEditingController();
  final TextEditingController _emailController           = TextEditingController();
  final TextEditingController _passwordController        = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController           = TextEditingController();
  final TextEditingController _adminCodeController       = TextEditingController();
  final TextEditingController _companyController         = TextEditingController();

  final List<bool> _selections = [true, false];
  String get _selectedRole => _selections[0] ? 'viewer' : 'admin';

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _adminCodeController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // ─── 기존 로직: 회원가입 핸들러 (완벽 보존) ──────────────────
  Future<void> _handleSignUp() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final errorMessage = await authViewModel.signUp(
      name:            _nameController.text,
      email:           _emailController.text,
      password:        _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role:            _selectedRole,
      phone:           _phoneController.text,
      adminCode:       _adminCodeController.text,
      company:         _companyController.text,
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
          content: Text('회원가입이 완료되었습니다!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _brandingBlue,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bgOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 헤더 ──────────────────────────────────────
            _buildHeader(),

            // ── 스크롤 가능한 폼 영역 ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 유형 선택
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('사용자 유형 선택',
                              style: TextStyle(
                                  color: _charcoal,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _typeCard(
                                  index: 0,
                                  title: '일반 사용자',
                                  subtitle: 'General',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _typeCard(
                                  index: 1,
                                  title: '현장 관리자',
                                  subtitle: 'Admin',
                                  icon: Icons.admin_panel_settings_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 관리자 전용 섹션
                    if (!_selections[0]) ...[
                      const SizedBox(height: 20),
                      _sectionCard(
                        highlight: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user_outlined, color: _brandingBlue, size: 18),
                                SizedBox(width: 8),
                                Text('관리자 인증 정보',
                                    style: TextStyle(
                                        color: _brandingBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('관리자 인증 코드'),
                            _inputField(
                              controller: _adminCodeController,
                              hint: '인증 코드 입력',
                              icon: Icons.vpn_key_outlined,
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('소속 기관'),
                            _inputField(
                              controller: _companyController,
                              hint: '소속 회사 또는 기관명',
                              icon: Icons.business_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 기본 정보 입력 섹션
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('이름'),
                          _inputField(
                            controller: _nameController,
                            hint: '홍길동',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('이메일'),
                          _inputField(
                            controller: _emailController,
                            hint: 'example@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('전화번호'),
                          _inputField(
                            controller: _phoneController,
                            hint: '010-0000-0000',
                            icon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('비밀번호'),
                          _passwordField(
                            controller: _passwordController,
                            isConfirm: false,
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('비밀번호 확인'),
                          _passwordField(
                            controller: _confirmPasswordController,
                            isConfirm: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 가입 완료 버튼
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: _brandingBlue))
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _handleSignUp,
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('가입 완료',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandingBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),

                    // 로그인 이동
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: _lightGrey),
                        child: RichText(
                          text: const TextSpan(
                            text: '이미 계정이 있나요? ',
                            style: TextStyle(color: _lightGrey, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '로그인',
                                style: TextStyle(
                                    color: _brandingBlue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _brandingBlue,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _brandingBlue.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.verified_user_outlined,
                size: 38, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            '신규 계정 생성',
            style: TextStyle(
              color: _charcoal,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '시스템 사용을 위해 정보를 입력하세요.',
            style: TextStyle(
              color: _lightGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child, bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? _brandingBlue.withValues(alpha: 0.3) : _borderLight,
          width: highlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: _charcoal),
      ),
    );
  }

  Widget _typeCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selections[index];
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? _brandingBlue.withValues(alpha: 0.05) : _cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _brandingBlue : _borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _brandingBlue.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 36,
                color: isSelected ? _brandingBlue : _lightGrey),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? _brandingBlue : _charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? _brandingBlue.withValues(alpha: 0.8) : _lightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _charcoal, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _lightGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: _lightGrey, size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _brandingBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool isConfirm,
  }) {
    final bool obscure =
        isConfirm ? _obscureConfirmPassword : _obscurePassword;

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _charcoal, fontSize: 15),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: _lightGrey, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _lightGrey, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _lightGrey,
            size: 20,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _brandingBlue, width: 1.5),
        ),
      ),
    );
  }
}
