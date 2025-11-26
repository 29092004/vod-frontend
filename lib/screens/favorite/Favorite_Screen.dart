import 'package:flutter/material.dart';
import '../../models/History.dart';
import '../../services/History_Service.dart';
import '../detail/Detail_Films.dart';

import '../../services/auth_service.dart';
import '../../config/api.dart';
import 'favorite_movies_screen.dart';
import 'favorite_watchlists_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _showContinue = false;
  bool _loading = false;
  List<History> _continueList = [];

  int _profileId = 0; // ❗Không xét cứng nữa

  @override
  void initState() {
    super.initState();
    _loadProfileId(); // 🔥 lấy profile ID thật
  }

  Future<void> _loadProfileId() async {
    await Api.loadToken();
    final me = await AuthService.getMe();
    final user = me?['user'];

    if (user != null) {
      setState(() {
        _profileId = user['Profile_id'] ?? user['profile_id'] ?? user['id'];
      });
    }
  }

  Future<void> _loadContinueWatching() async {
    if (_profileId == 0) return; // ⛔ chưa load xong thì không gọi API

    setState(() => _loading = true);
    try {
      final data = await HistoryService.getContinueWatching(_profileId);
      setState(() {
        _continueList = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFromContinue(int historyId) async {
    try {
      await HistoryService.deleteHistory(historyId);
      setState(() {
        _continueList.removeWhere((item) => item.historyId == historyId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi khi xóa: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
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
            icon: Icons.favorite_rounded,
            title: "Yêu thích",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteMoviesScreen()),
              );
            },
          ),
          _divider(),
          _buildSectionItem(
            icon: Icons.add_rounded,
            title: "Danh sách",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoriteWatchListsScreen(),
                ),
              );
            },
          ),

          _divider(),

          // 🔹 XEM TIẾP
          ListTile(
            onTap: () async {
              setState(() => _showContinue = !_showContinue);

              if (_showContinue && _continueList.isEmpty) {
                await _loadContinueWatching();
              }
            },
            leading: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 28,
            ),
            title: const Text(
              "Xem tiếp",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _showContinue
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: _showContinue ? 24 : 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
          ),

          if (_showContinue) _buildContinueList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Widget từng mục --- //
  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.white38,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.white24, thickness: 0.8, height: 8),
    );
  }

  // --- Giao diện danh sách phim XEM TIẾP --- //
  Widget _buildContinueList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

    if (_continueList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          "Chưa có phim nào đang xem tiếp.",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: SizedBox(
        height: 330,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _continueList.length,
          itemBuilder: (context, index) {
            final item = _continueList[index];
            final percent = item.progressPercent;

            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailFilmScreen(
                      filmId: item.filmId,
                      episodeId: item.episodeId,
                      startPosition: Duration(seconds: item.positionSeconds),
                    ),
                  ),
                );

                // Nếu DetailFilmScreen trả về giá trị mới → reload từ API
                if (result != null) {
                  await _loadContinueWatching(); // Lấy dữ liệu mới từ DB trả về
                }
              },
              child: Container(
                width: 180,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Poster
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.posterUrl,
                            width: 180,
                            height: 230,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // --- nút xóa
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () => _removeFromContinue(item.historyId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        // --- tiến độ
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.black26,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- Thông tin
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Tập ${item.episodeNumber ?? 1} • ${(item.positionSeconds ~/ 60)}m / ${(item.durationSeconds ~/ 60)}m",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // --- Tên phim
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item.filmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
