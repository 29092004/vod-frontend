import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _user; // Lưu thông tin người dùng
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await AuthService.getMe();
    setState(() {
      _user = userData?['user']; // backend trả về { success: true, user: {...} }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Header: avatar + email hoặc đăng nhập
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage: _user != null &&
                          _user!['avatar'] != null &&
                          _user!['avatar'] != ''
                          ? NetworkImage(_user!['avatar'])
                          : null,
                      child: (_user == null ||
                          _user!['avatar'] == null ||
                          _user!['avatar'] == '')
                          ? const Icon(Icons.person,
                          size: 40, color: Colors.black54)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // 🔹 Hiển thị email hoặc nút đăng nhập
                    Expanded(
                      child: GestureDetector(
                        onTap: _user == null
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }
                            : null,
                        child: Text(
                          _user != null
                              ? (_user!['email'] ??
                              _user!['name'] ??
                              'Người dùng')
                              : "Đăng nhập / Đăng ký",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.grey, thickness: 0.2),

              _buildMenuItem(Icons.history, "Lịch sử xem", () {}),
              _buildMenuItem(Icons.language, "Ngôn ngữ", () {}),
              _buildMenuItem(Icons.settings, "Cài đặt", () {}),

              const SizedBox(height: 30),

              //  Nút đăng xuất
              if (_user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Đăng xuất",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      await _logout(context);
                    },
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  // 🔹 Hàm xử lý đăng xuất
  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout();

      // 🔹 Xóa thông tin user
      setState(() => _user = null);

      // 🔹 Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đăng xuất thành công")),
      );

      // 🔹 Điều hướng về LoginScreen (xóa toàn bộ stack cũ)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi đăng xuất: $e")),
      );
    }
  }

}
