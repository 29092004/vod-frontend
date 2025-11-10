import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Màu nền tối
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Danh mục của bạn",
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildSectionItem(
            context,
            icon: Icons.favorite_rounded,
            title: "Yêu thích",
            color: Colors.white,
            onTap: () {
            },
          ),

          _divider(),
          _buildSectionItem(
            context,
            icon: Icons.add_rounded,
            title: "Danh sách",
            color: Colors.white,
            onTap: () {
            },
          ),
          _divider(),
          _buildSectionItem(
            context,
            icon: Icons.history_rounded,
            title: "Xem tiếp",
            color: Colors.white,
            onTap: () {
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Widget tạo từng mục ---
  Widget _buildSectionItem(BuildContext context,
      {required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.white38),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  // --- Phân cách giữa các mục ---
  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: Colors.white24,
        thickness: 0.8,
        height: 8,
      ),
    );
  }
}
