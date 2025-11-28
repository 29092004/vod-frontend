import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/Payment_Service.dart';
import '../auth/login.dart';
import '../../services/auth_service.dart';
import '../../config/api.dart';
import '../payment/payment_history_screen.dart';
import '../payment/payment_webview.dart';

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

  // Format hạn Premium
  String _formatDate(dynamic date) {
    if (date == null) return "—";
    try {
      final d = DateTime.parse(date.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return date.toString();
    }
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
              // ================= HEADER AVATAR ===================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                              builder: (_) =>
                              const LoginScreen(),
                            ),
                          );
                        }
                            : null,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // ===== NAME + PREMIUM ICON =====
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

                                //  Icon Premium
                                if (_user != null &&
                                    _user!['is_premium'] == 1)
                                  const Icon(Icons.workspace_premium,
                                      color: Colors.amber, size: 22),

                                if (_user != null)
                                  IconButton(
                                    onPressed: () =>
                                        _changeDisplayName(context),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white70,
                                        size: 18),
                                  ),
                              ],
                            ),

                            // ===== EMAIL =====
                            if (_user != null &&
                                _user!['email'] != null)
                              Text(
                                _user!['email'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                            const SizedBox(height: 4),

                            // ===== PREMIUM STATUS =====
                            if (_user != null)
                              Row(
                                children: [
                                  Icon(
                                    _user!['is_premium'] == 1
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: _user!['is_premium'] == 1
                                        ? Colors.amber
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),

                                  if (_user!['is_premium'] == 1)
                                    Text(
                                      "Premium (hết hạn: ${_formatDate(_user!['premium_expired'])})",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    const Text(
                                      "Tài khoản miễn phí",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
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

              // ================= BUTTON PREMIUM ===================
              if (_user != null && _user!['is_premium'] != 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showPremiumOptions(context),
                    child: const Text(
                      "✨ Nâng cấp tài khoản",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const Divider(color: Colors.grey, thickness: 0.2),

              // ================= MENU ===================
              _buildMenuItem(Icons.history, "Lịch sử thanh toán", () {
                if (_user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentHistoryScreen(
                      accountId: _user!["id"],
                    ),
                  ),
                );
              }),
              _buildMenuItem(Icons.language, "Ngôn ngữ", () {}),
              _buildMenuItem(Icons.settings, "Cài đặt", () {}),

              const SizedBox(height: 30),

              // ================= LOGOUT ===================
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
                    icon: const Icon(Icons.logout,
                        color: Colors.white),
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

  // ======================= AVATAR HANDLER ==========================
  ImageProvider? _buildAvatarImage() {
    if (_user == null || _user!['avatar'] == null) return null;

    final avatar = _user!['avatar'].toString().trim();
    if (avatar.isEmpty) return null;

    if (avatar.startsWith('http')) return NetworkImage(avatar);
    if (avatar.startsWith('/storage') || avatar.startsWith('/data')) {
      return FileImage(File(avatar));
    }
    if (avatar.startsWith('file://')) {
      return FileImage(File(Uri.parse(avatar).path));
    }
    if (!avatar.contains('://')) {
      final normalized = avatar.startsWith('/') ? avatar : '/$avatar';
      return NetworkImage('${Api.baseHost}$normalized');
    }

    return null;
  }

  // ======================= MENU ITEM ==========================
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing:
      const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  // ======================= LOGOUT ==========================
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

  // ======================= CHANGE NAME ==========================
  Future<void> _changeDisplayName(BuildContext context) async {
    final nameController =
    TextEditingController(text: _user?['name'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đổi tên hiển thị',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              try {
                final profileId =
                    _user?['profile_id'] ?? _user?['Profile_id'];

                await Api.put('profiles/$profileId', {
                  'profile_name': newName,
                });

                setState(() => _user!['name'] = newName);

                await _loadUser();
              } catch (_) {}
            },
            child: const Text('Lưu',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ======================= PREMIUM BOTTOM SHEET ==========================
  void _showPremiumOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nâng cấp tài khoản VTC Film",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Chọn gói Premium để tăng trải nghiệm xem phim.",
                style:
                TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              _premiumPlanItem(months: 1, price: 39000),
              _premiumPlanItem(months: 6, price: 189000, sale: "Giảm 19%"),
              _premiumPlanItem(months: 12, price: 339000, sale: "Giảm 28%"),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _premiumPlanItem({
    required int months,
    required int price,
    String? sale,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$months tháng",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${price ~/ 1000}K ₫",
                style: const TextStyle(
                    color: Colors.white, fontSize: 16),
              ),
              if (sale != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sale,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),

          const Spacer(),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _requestPremiumPayment(months, price);
            },
            child: const Text("Mua"),
          ),
        ],
      ),
    );
  }

  // ======================= HANDLE PAYMENT ==========================
  void _requestPremiumPayment(int months, int price) async {
    final accountId = _user?['id'] ?? _user?['account_id'];

    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy tài khoản")),
      );
      return;
    }

    final url = await PaymentService.createPremiumPayment(
      accountId: accountId,
      amount: price,
      months: months,
    );

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không lấy được link thanh toán")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebView(paymentUrl: url),
      ),
    );

// Nếu thanh toán thành công → reload user
    if (result == true) {
      await _loadUser();  // cập nhật Premium
      setState(() {});
    }

  }
}
