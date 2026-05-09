import 'package:flutter/material.dart';

class FindPasswordView extends StatefulWidget {
  const FindPasswordView({super.key});

  @override
  State<FindPasswordView> createState() => _FindPasswordViewState();
}

class _FindPasswordViewState extends State<FindPasswordView> {
  // ─── 대시보드 동기화 색상 토큰 ───────────────────────────
  static const Color _bgOffWhite  = Color(0xFFF8F9FA);
  static const Color _cardWhite   = Color(0xFFFFFFFF);
  static const Color _charcoal    = Color(0xFF212529);
  static const Color _lightGrey   = Color(0xFF6C757D);
  static const Color _brandingBlue = Color(0xFF3761F3);
  static const Color _borderLight = Color(0xFFDEE2E6);

  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _handleFindPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일을 입력해주세요.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Mock API call delay (기존 로직 보존)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('비밀번호 재설정 링크가 전송되었습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandingBlue,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // 1. 헤더 아이콘 및 타이틀
                _buildHeader(),
                const SizedBox(height: 40),
                
                // 2. 메인 입력 카드
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
                      const Text(
                        '가입 시 등록한 이메일 주소를 입력해 주세요.\n비밀번호 재설정 링크를 보내드립니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _lightGrey,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('이메일 주소', 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _charcoal)),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: _charcoal),
                        decoration: InputDecoration(
                          hintText: 'example@email.com',
                          hintStyle: const TextStyle(color: _lightGrey, fontSize: 14),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: _lightGrey, size: 22),
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
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 발송 버튼
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: _brandingBlue))
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _handleFindPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandingBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('재설정 링크 보내기', 
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                      const SizedBox(height: 24),
                      
                      // 로그인 이동
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(foregroundColor: _lightGrey),
                          child: RichText(
                            text: const TextSpan(
                              text: '계정이 기억나셨나요? ',
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
                const SizedBox(height: 40),
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
          child: const Icon(Icons.lock_reset_rounded, size: 42, color: Colors.white),
        ),
        const SizedBox(height: 28),
        const Text(
          '비밀번호 찾기',
          style: TextStyle(
            color: _charcoal,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '안전한 서비스 이용을 위해 비밀번호를 재설정하세요.',
          style: TextStyle(
            color: _lightGrey,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
