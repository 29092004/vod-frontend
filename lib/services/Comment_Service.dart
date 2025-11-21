import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';

class CommentService {
  // ============================================================
  // 🔥 1) Lấy toàn bộ comment + replies (nested)
  // ============================================================
  static Future<List<Map<String, dynamic>>> getComments(int filmId) async {
    try {
      final res = await Api.get('comments/$filmId');

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);

      if (data is Map && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }

      return [];
    } catch (e) {
      print("❌ Lỗi getComments: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 2) Lấy danh sách replies cho từng comment
  // ============================================================
  static Future<List<Map<String, dynamic>>> getReplies(int parentId) async {
    try {
      final res = await Api.get('comments/replies/$parentId');

      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }

      return [];
    } catch (e) {
      print("❌ Lỗi getReplies: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 3) Gửi bình luận mới (không có parent)
  // ============================================================
  static Future<bool> addComment({
    required int filmId,
    required int profileId,
    required String content,
  }) async {
    try {
      final res = await Api.post('comments/', {
        "film_id": filmId,
        "profile_id": profileId,
        "content": content,
      });

      return res.data['success'] == true;
    } catch (e) {
      print("❌ Lỗi addComment: $e");
      return false;
    }
  }

  // ============================================================
  // 🔥 4) Gửi reply (có parent_id)
  // ============================================================
  static Future<bool> addReply({
    required int filmId,
    required int profileId,
    required int parentId,
    required String content,
  }) async {
    try {
      final res = await Api.post('comments/reply', {
        "film_id": filmId,
        "profile_id": profileId,
        "parent_id": parentId,
        "content": content,
      });

      return res.data['success'] == true;
    } catch (e) {
      print("❌ Lỗi addReply: $e");
      return false;
    }
  }

  // ============================================================
  // 🔥 5) Like comment
  // ============================================================
  static Future<bool> likeComment(int commentId) async {
    try {
      final res = await Api.post('comments/like/$commentId', {});
      return res.data['success'] == true;
    } catch (e) {
      print("❌ Lỗi likeComment: $e");
      return false;
    }
  }

  // ============================================================
  // 🔥 6) Xoá comment
  // ============================================================
  static Future<bool> deleteComment(int commentId) async {
    try {
      final res = await Api.delete('comments/$commentId');
      return res.data['success'] == true;
    } catch (e) {
      print("❌ Lỗi deleteComment: $e");
      return false;
    }
  }

  // ============================================================
  // 🔥 Helper parse ngày
  // ============================================================
  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}
