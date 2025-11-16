import 'package:flutter/material.dart';
import 'package:movie_app/screens/favorite/watchlist_movies_screen.dart';

import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../services/WatchList_Service.dart';
import '../../models/watchlist.dart';
// (sau này nếu có màn xem phim trong 1 danh sách, ta sẽ import thêm ở đây)

class FavoriteWatchListsScreen extends StatefulWidget {
  const FavoriteWatchListsScreen({super.key});

  @override
  State<FavoriteWatchListsScreen> createState() =>
      _FavoriteWatchListsScreenState();
}

class _FavoriteWatchListsScreenState extends State<FavoriteWatchListsScreen> {
  int _profileId = 0;
  bool _isLoading = true;
  String? _error;
  List<WatchList> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Api.loadToken();
      final me = await AuthService.getMe();
      final user = me?['user'];

      int profileId = 0;
      if (user != null) {
        profileId = user['Profile_id'] ?? user['profile_id'] ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _profileId = profileId;
      });

      if (profileId == 0) {
        setState(() {
          _isLoading = false;
          _error = 'Vui lòng đăng nhập để xem danh sách phim của bạn.';
        });
        return;
      }

      await _loadWatchLists();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _loadWatchLists() async {
    if (_profileId == 0) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await WatchListService.getByProfile(_profileId);
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không tải được danh sách phim của bạn';
        _items = [];
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  final TextEditingController _newListController = TextEditingController();

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  Future<void> _showCreateWatchListDialog() async {
    if (_profileId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo danh sách')),
      );
      return;
    }

    _newListController.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tạo danh sách mới'),
          content: TextField(
            controller: _newListController,
            decoration: const InputDecoration(hintText: 'Nhập tên danh sách'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final name = _newListController.text.trim();
                if (name.isEmpty) return;

                Navigator.of(ctx).pop();

                final ok = await WatchListService.createWatchList(
                  profileId: _profileId,
                  name: name,
                );

                if (!mounted) return;

                if (ok != null) {
                  await _loadWatchLists();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã tạo danh sách "$name"')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể tạo danh sách mới'),
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Danh sách phim',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateWatchListDialog,
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _init, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Bạn chưa tạo danh sách phim nào.\nHãy thêm phim từ trang chi tiết để bắt đầu!',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWatchLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final wl = _items[index];
          final created = _formatDate(wl.createdAt);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WatchListMoviesScreen(watchList: wl),
                ),
              );
            },

            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF141414),
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Row(
                children: [
                  // Icon bên trái
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.95),
                          Colors.deepOrange.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.playlist_play_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  // Nội dung
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wl.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            created.isNotEmpty
                                ? 'Tạo ngày $created'
                                : 'Danh sách phim cá nhân',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
