import 'package:flutter/material.dart';

import '../../models/watchlist.dart';
import '../../models/watchlist_movie.dart';
import '../../services/WatchListItem_Service.dart';

class WatchListMoviesScreen extends StatefulWidget {
  final WatchList watchList;

  const WatchListMoviesScreen({super.key, required this.watchList});

  @override
  State<WatchListMoviesScreen> createState() => _WatchListMoviesScreenState();
}

class _WatchListMoviesScreenState extends State<WatchListMoviesScreen> {
  bool _isLoading = true;
  String? _error;
  List<WatchListMovie> _movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WatchListItemService.getMoviesOfWatchList(
        widget.watchList.id,
      );
      if (!mounted) return;
      setState(() {
        _movies = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải danh sách phim';
      });
    }
  }

  Future<void> _removeMovie(WatchListMovie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phim khỏi danh sách'),
        content: Text('Bạn có chắc muốn xóa "${movie.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await WatchListItemService.removeFilmFromWatchList(
      watchListId: widget.watchList.id,
      filmId: movie.filmId,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _movies.removeWhere((m) => m.filmId == movie.filmId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa phim khỏi danh sách')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa không thành công')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.watchList.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadMovies,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Danh sách này chưa có phim nào.\nHãy thêm phim từ trang chi tiết.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Giao diện dạng grid giống favorite_movies_screen
    return RefreshIndicator(
      onRefresh: _loadMovies,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.6,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          final poster = movie.posterUrl ?? '';

          return GestureDetector(
            onLongPress: () => _removeMovie(movie),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: poster.isNotEmpty
                        ? Image.network(
                            poster,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.movie_creation_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  movie.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  movie.isSeries ? 'Phim bộ' : 'Phim lẻ',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
