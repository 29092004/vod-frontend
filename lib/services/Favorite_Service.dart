import 'package:dio/dio.dart';
import '../config/api.dart';

class FavoriteService {
  /// Kiểm tra film có nằm trong danh sách yêu thích của profile không
  static Future<bool> isFavorite(int profileId, int filmId) async {
    if (profileId == 0) return false;

    try {
      await Api.loadToken();
      final Response res = await Api.get('/favorites/profile/$profileId');

      final body = res.data;
      if (body is! Map) return false;

      final list = body['data'];
      if (list is! List) return false;

      return list.any((item) {
        if (item is! Map) return false;
        final fid = item['Film_id'] ?? item['film_id'] ?? item['filmId'];

        if (fid is String) {
          return int.tryParse(fid) == filmId;
        }
        if (fid is num) {
          return fid.toInt() == filmId;
        }
        return false;
      });
    } on DioException catch (e) {
      print('Lỗi isFavorite: ${Api.handleError(e)}');
      return false;
    } catch (e) {
      print('Lỗi không xác định isFavorite: $e');
      return false;
    }
  }

  /// Thêm vào danh sách yêu thích
  static Future<bool> addFavorite({
    required int profileId,
    required int filmId,
  }) async {
    try {
      await Api.loadToken();

      final Response res = await Api.post('/favorites', {
        'profile_id': profileId,
        'film_id': filmId,
      });

      final body = res.data;

      if (body is Map && body['success'] == true) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      final r = e.response;
      if (r != null && r.statusCode == 400) {
        final data = r.data;
        if (data is Map &&
            data['error'] == 'Phim này đã có trong danh sách yêu thích') {
          return true;
        }
      }

      print('Lỗi addFavorite: ${Api.handleError(e)}');
      return false;
    } catch (e) {
      print('Lỗi không xác định addFavorite: $e');
      return false;
    }
  }

  /// Xoá khỏi danh sách yêu thích
  static Future<bool> removeFavorite(int profileId, int filmId) async {
    try {
      await Api.loadToken();
      final Response res = await Api.delete('/favorites/$profileId/$filmId');

      final body = res.data;
      if (body is Map && body['success'] == true) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      // Nếu BE trả 404: không còn trong danh sách -> coi như đã xoá xong
      if (e.response?.statusCode == 404) {
        return true;
      }

      print('Lỗi removeFavorite: ${Api.handleError(e)}');
      return false;
    } catch (e) {
      print('Lỗi không xác định removeFavorite: $e');
      return false;
    }
  }

  /// Lấy danh sách favorite theo profile
  static Future<List<Map<String, dynamic>>> getFavoritesByProfile(int profileId) async {
    if (profileId == 0) return [];

    await Api.loadToken();
    final Response res = await Api.get('/favorites/profile/$profileId');

    final body = res.data;
    if (body is Map && body['success'] == true) {
      final data = body['data'];
      if (data is List) {
        return data
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }

    return [];
  }
}
