import 'dart:io';
import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../../services/auth_service.dart';
import '../../config/api.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await AuthService.getMe();
    setState(() {
      _user = userData?['user'];
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar người dùng
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: _buildAvatarImage(),
                      child: (_user == null ||
                          _user!['avatar'] == null ||
                          _user!['avatar'].toString().isEmpty)
                          ? const Icon(Icons.person,
                          size: 40, color: Colors.white70)
                          : null,
                    ),

                    const SizedBox(width: 12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _user != null
                                        ? (_user!['name'] ??
                                        _user!['email'] ??
                                        'Người dùng')
                                        : "Đăng nhập / Đăng ký",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_user != null)
                                  IconButton(
                                    onPressed: () =>
                                        _changeDisplayName(context),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white70, size: 18),
                                    tooltip: "Đổi tên hiển thị",
                                  ),
                              ],
                            ),
                            if (_user != null && _user!['email'] != null)
                              Text(
                                _user!['email'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                          ],
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
                    onPressed: () async => _logout(context),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 🟢 Hàm chọn loại ImageProvider an toàn
  ImageProvider? _buildAvatarImage() {
    if (_user == null || _user!['avatar'] == null) return null;

    final avatar = _user!['avatar'].toString().trim();
    if (avatar.isEmpty) return null;

    if (avatar.startsWith('http')) {
      // URL mạng
      return NetworkImage(avatar);
    } else if (avatar.startsWith('/storage') || avatar.startsWith('/data')) {
      // File cục bộ
      return FileImage(File(avatar));
    } else if (avatar.startsWith('file://')) {
      // File cục bộ có prefix
      return FileImage(File(Uri.parse(avatar).path));
    } else if (!avatar.contains('://')) {

      return NetworkImage('${Api.baseHost}$avatar');
    }

    return null;
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
  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      setState(() => _user = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã đăng xuất thành công")),
      );
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
  Future<void> _changeDisplayName(BuildContext context) async {
    final nameController = TextEditingController(text: _user?['name'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đổi tên hiển thị',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.redAccent,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tên không được để trống")),
                );
                return;
              }

              Navigator.pop(context);

              try {
                // Lấy ID profile
                final profileId = _user?['profile_id'] ?? _user?['Profile_id'];
                if (profileId == null) {
                  throw Exception("Không tìm thấy ID profile để cập nhật");
                }
                final res = await Api.put('profiles/$profileId', {
                  'profile_name': newName,
                });

                if (res.data['success'] == true) {
                  // Cập nhật UI ngay
                  setState(() {
                    _user!['name'] = newName;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(" Cập nhật tên hiển thị thành công"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  //  Gọi lại getMe() để refresh dữ liệu user thật từ server
                  await _loadUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(" Không thể cập nhật tên hiển thị"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Lỗi khi cập nhật: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

}
