import 'package:flutter/material.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../services/Favorite_Service.dart';
import '../detail/Detail_Films.dart';

class FavoriteMoviesScreen extends StatefulWidget {
  const FavoriteMoviesScreen({super.key});

  @override
  State<FavoriteMoviesScreen> createState() => _FavoriteMoviesScreenState();
}

class _FavoriteMoviesScreenState extends State<FavoriteMoviesScreen> {
  int _profileId = 0;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      setState(() => _profileId = profileId);

      if (_profileId == 0) {
        setState(() {
          _isLoading = false;
          _items = [];
        });
        return;
      }

      await _loadFavorites();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (_profileId == 0) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await FavoriteService.getFavoritesByProfile(_profileId);
      if (!mounted) return;

      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không tải được danh sách yêu thích';
        _items = [];
      });
    }
  }

  // ===== Helpers =====
  int _getFilmId(Map<String, dynamic> item) {
    final v = item['Film_id'] ?? item['film_id'] ?? item['filmId'] ?? item['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _getFilmName(Map<String, dynamic> item) {
    return (item['Film_name'] ??
        item['film_name'] ??
        item['Name'] ??
        item['name'] ??
        "Không rõ tên")
        .toString();
  }

  String _getOriginalName(Map<String, dynamic> item) {
    return (item['Original_name'] ??
        item['original_name'] ??
        item['OriginalName'] ??
        item['originalName'] ??
        "")
        .toString();
  }

  String? _getPoster(Map<String, dynamic> item) {
    final raw = item['Poster_url'] ??
        item['poster_url'] ??
        item['Image'] ??
        item['image'];

    if (raw == null) return null;

    final s = raw.toString();
    if (s.startsWith('http')) return s;

    return "${Api.baseHost}$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Yêu thích',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_profileId == 0) {
      return const Center(
        child: Text(
          'Vui lòng đăng nhập để xem danh sách phim yêu thích.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadFavorites,
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa có phim nào trong danh sách yêu thích.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.63,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          final filmId = _getFilmId(item);
          final title = _getFilmName(item);

          final poster = _getPoster(item);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailFilmScreen(filmId: filmId)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: poster != null
                        ? Image.network(
                      poster,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.movie,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Tên phim
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),


              ],
            ),
          );
        },
      ),
    );
  }
}
