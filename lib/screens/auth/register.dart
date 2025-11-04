import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Đăng ký",
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

          // Nội dung chính
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  children: [
                    const Text(
                      "Tạo tài khoản mới",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(
                              label: "Email",
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Vui lòng nhập email";
                              if (!v.contains("@")) return "Email không hợp lệ";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _password,
                            obscureText: _obscure1,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(
                              label: "Mật khẩu",
                              icon: Icons.lock_outline,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscure1 ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            validator: (v) =>
                            v!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure2,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(
                              label: "Xác nhận mật khẩu",
                              icon: Icons.lock_reset,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscure2 ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) =>
                            v != _password.text ? "Mật khẩu không khớp" : null,
                          ),
                          const SizedBox(height: 24),

                          // 🔹 Nút đăng ký
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
                              onPressed: _loading ? null : _handleRegister,
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
                                "Đăng ký",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          //  Chuyển sang đăng nhập
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Bạn đã có tài khoản? ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Đăng nhập ngay",
                                  style: TextStyle(color: Colors.green),
                                ),
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
          ),
        ],
      ),
    );
  }

  //  Hàm xử lý đăng ký thật
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final res = await AuthService.register(_email.text, _password.text);

    setState(() => _loading = false);

    if (res['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error']), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Chuyển sang màn login
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  //  Input style tái sử dụng
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
