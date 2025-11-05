import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register.dart';
import '../../screens/home/Home_Screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await AuthService.login(_email.text, _pass.text);
    setState(() => _loading = false);

    if (!mounted) return;

    if (res['error'] != null) {
      //  Đăng nhập thất bại
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error']),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    //  Đợi 0.8s rồi chuyển sang HomeScreen
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      final user = res['user'] ?? {};
      final email = user['email'] ?? '';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(email: email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đăng nhập",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              'assets/anh_chinh/anh_nen_login_chinh.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Lớp phủ mờ
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Nội dung
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.movie_creation_outlined,
                            color: Colors.green, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'VTC Movie',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục xem phim chất lượng cao',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 22),

                    // Form đăng nhập
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111114).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputStyle(
                                label: 'Email',
                                icon: Icons.alternate_email_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                final ok = RegExp(
                                    r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                                    .hasMatch(v);
                                return ok ? null : 'Email không hợp lệ';
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _pass,
                              obscureText: _obscure,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputStyle(
                                label: 'Mật khẩu',
                                icon: Icons.lock_outline_rounded,
                                trailing: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => v!.length < 6
                                  ? 'Mật khẩu tối thiểu 6 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            // Remember me
                            Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (v) =>
                                      setState(() => _remember = v ?? true),
                                  activeColor: Colors.green,
                                  side: const BorderSide(color: Colors.white54),
                                ),
                                const Text('Nhớ tôi',
                                    style: TextStyle(color: Colors.white70)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Quên mật khẩu?',
                                      style: TextStyle(color: Colors.green)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Nút Đăng nhập
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _loading ? null : _onLogin,
                                child: _loading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                    : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                            // 🔹 Nút đăng nhập bằng Google
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: const Color(0xFF1A1B1E).withOpacity(0.9),
                                ),
                                icon: Image.asset(
                                  'assets/icons/google.png', // bạn cần có icon này
                                  width: 24,
                                  height: 24,
                                ),
                                label: const Text(
                                  'Đăng nhập bằng Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () async {
                                  final result = await AuthService.signInWithGoogle();
                                  if (!mounted) return;

                                  if (result['error'] != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['error']), backgroundColor: Colors.redAccent),
                                    );
                                  } else {
                                    // Nếu thành công → chuyển sang HomeScreen
                                    final user = result['user'] ?? {};
                                    final email = user['email'] ?? '';

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => HomeScreen(email: email)),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Đăng ký
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Chưa có tài khoản? ',
                                    style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, animation, __) =>
                                        const RegisterScreen(),
                                        transitionsBuilder:
                                            (_, anim, __, child) =>
                                            SlideTransition(
                                              position: Tween(
                                                  begin:
                                                  const Offset(1.0, 0.0),
                                                  end: Offset.zero)
                                                  .animate(CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeInOut)),
                                              child: child,
                                            ),
                                        transitionDuration:
                                        const Duration(milliseconds: 400),
                                      ),
                                    );
                                  },
                                  child: const Text('Đăng ký ngay',
                                      style: TextStyle(color: Colors.green)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
    Widget? trailing,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: trailing,
      filled: true,
      fillColor: const Color(0xFF1A1B1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green),
      ),
    );
  }
}
