import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';

class CommentService {
  //  Lấy danh sách bình luận (kèm phản hồi)
  static Future<List<Map<String, dynamic>>> getComments(int filmId) async {
    try {
      final res = await Api.get('comments/$filmId');
      dynamic data = res.data;

      if (data is String) data = jsonDecode(data);
      if (data is Map && data['success'] == true) {
        final list = data['data'];
        if (list is List) return List<Map<String, dynamic>>.from(list);
      }
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      return [];
    }
  }

  //  Lấy phản hồi riêng của một bình luận
  static Future<List<Map<String, dynamic>>> getReplies(int parentId) async {
    try {
      final res = await Api.get('comments/replies/$parentId');
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
      return [];
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      throw Exception(Api.handleError(e));
    }
  }

  //  Thêm bình luận hoặc phản hồi
  static Future<bool> addComment({
    required int filmId,
    required int profileId,
    required String content,
    int? parentId,
  }) async {
    try {
      final res = await Api.post('comments', {
        'film_id': filmId,
        'profile_id': profileId,
        'content': content,
        'parent_id': parentId,
      });
      return res.data['success'] == true;
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      throw Exception(Api.handleError(e));
    }
  }

  //  Alias cho phản hồi
  static Future<bool> addReply({
    required int filmId,
    required int profileId,
    required int parentId,
    required String content,
  }) async {
    return await addComment(
      filmId: filmId,
      profileId: profileId,
      parentId: parentId,
      content: content,
    );
  }

  // Like bình luận
  static Future<bool> likeComment(int commentId) async {
    try {
      final res = await Api.post('comments/like/$commentId', {});
      return res.data['success'] == true;
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      throw Exception(Api.handleError(e));
    }
  }

  //  Xóa bình luận
  static Future<bool> deleteComment(int commentId) async {
    try {
      final res = await Api.delete('comments/$commentId');
      return res.data['success'] == true;
    } on DioException catch (e) {
      print(" Lỗi: ${e.message}");
      throw Exception(Api.handleError(e));
    }
  }

  //  Helper parse thời gian
  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}
