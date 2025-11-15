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
      setState(() {
        _profileId = profileId;
      });

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

  int _getFilmId(Map<String, dynamic> item) {
    final v =
        item['Film_id'] ?? item['film_id'] ?? item['filmId'] ?? item['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _getTitle(Map<String, dynamic> item) {
    return (item['Film_name'] ??
            item['film_name'] ??
            item['Name'] ??
            item['name'] ??
            'Không rõ tên')
        .toString();
  }

  String? _getPoster(Map<String, dynamic> item) {
    final raw =
        item['Poster_url'] ??
        item['poster_url'] ??
        item['Image'] ??
        item['image'];
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return '${Api.baseHost}$s';
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Vui lòng đăng nhập để xem danh sách phim yêu thích.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadFavorites,
                child: const Text('Thử lại'),
              ),
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
            'Bạn chưa có phim nào trong danh sách yêu thích.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cột
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          final filmId = _getFilmId(item);
          final title = _getTitle(item);
          final poster = _getPoster(item);

          return GestureDetector(
            onTap: () {
              if (filmId == 0) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailFilmScreen(filmId: filmId),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 0.68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster
                    poster != null
                        ? Image.network(
                            poster,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),

                    // Gradient + title ở dưới
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
