import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';

class RatingService {
  //  Lấy toàn bộ rating
  static Future<List<dynamic>> getAllRatings() async {
    try {
      final res = await Api.get('ratings');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map && data['success'] == true && data['data'] != null) {
        return List<dynamic>.from(data['data']);
      }
      return [];
    } on DioException catch (e) {
      print(" Lỗi : ${e.message}");
      return [];
    }
  }

  //  Lấy danh sách đánh giá theo phim
  static Future<List<dynamic>> getRatingsByFilm(int filmId) async {
    try {
      final res = await Api.get('ratings/film/$filmId');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map && data['success'] == true && data['data'] != null) {
        return List<dynamic>.from(data['data']);
      }
      return [];
    } on DioException catch (e) {
      print(" Lỗi : ${e.message}");
      return [];
    }
  }

  //  Lấy danh sách đánh giá theo người dùng
  static Future<List<dynamic>> getRatingsByProfile(int profileId) async {
    try {
      final res = await Api.get('ratings/profile/$profileId');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map && data['success'] == true && data['data'] != null) {
        return List<dynamic>.from(data['data']);
      }
      return [];
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      return [];
    }
  }

  //  Gửi đánh giá (thêm hoặc cập nhật)
  static Future<bool> upsertRating({
    required int profileId,
    required int filmId,
    required double score,
    String? review,
  }) async {
    try {
      final res = await Api.post('ratings', {
        'profile_id': profileId,
        'film_id': filmId,
        'score': score,
        'review': review ?? '',
      });

      return res.data['success'] == true;
    } on DioException catch (e) {
      print(" Lỗi : ${e.message}");
      return false;
    }
  }

  //  Xóa đánh giá
  static Future<bool> deleteRating(int profileId, int filmId) async {
    try {
      final res = await Api.delete('ratings/$profileId/$filmId');
      return res.data['success'] == true;
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      return false;
    }
  }

  //  Lấy điểm trung bình của phim
  static Future<Map<String, dynamic>> getAverageScore(int filmId) async {
    try {
      final res = await Api.get('ratings/film/$filmId/average');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map && data['success'] == true) {
        return Map<String, dynamic>.from(data['data'] ??
            {'avg_score': 0, 'total_reviews': 0});
      }
      return {'avg_score': 0, 'total_reviews': 0};
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      return {'avg_score': 0, 'total_reviews': 0};
    }
  }
}
