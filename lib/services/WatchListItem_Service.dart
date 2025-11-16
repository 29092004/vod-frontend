import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/watchlist_movie.dart';

class WatchListItemService {
  /// Thêm 1 phim vào 1 watchlist
  static Future<bool> addFilmToWatchList({
    required int watchListId,
    required int filmId,
  }) async {
    await Api.loadToken();
    try {
      final res = await Api.post('/watchlistitems', {
        'watchlist_id': watchListId,
        'film_id': filmId,
      });
      final data = res.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      // Nếu muốn phân biệt lỗi "Phim đã có trong danh sách này", có thể:
      // final data = e.response?.data;
      // if (data is Map && data['error'] is String) {
      //   throw Exception(data['error']);
      // }
      rethrow;
    }
  }

  /// Xóa 1 phim khỏi 1 watchlist (sẽ dùng sau ở màn chi tiết danh sách)
  static Future<bool> removeFilmFromWatchList({
    required int watchListId,
    required int filmId,
  }) async {
    await Api.loadToken();
    final res = await Api.delete('/watchlistitems/$watchListId/$filmId');
    final data = res.data;
    return data is Map && data['success'] == true;
  }

  /// Lấy danh sách phim trong 1 watchlist
  static Future<List<WatchListMovie>> getMoviesOfWatchList(
    int watchListId,
  ) async {
    await Api.loadToken();
    try {
      final Response res = await Api.get(
        '/watchlistitems/watchlist/$watchListId',
      );

      final body = res.data;
      if (body is! Map) return [];

      final data = body['data'];
      if (data is! List) return [];

      return data
          .where((e) => e is Map)
          .map((e) => WatchListMovie.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException {
      return [];
    }
  }
}
