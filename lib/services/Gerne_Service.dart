import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Genre.dart';

class GenreService {
  static const String _endpoint = "/genres";

  /// 🔹 Lấy toàn bộ thể loại (chỉ lấy is_deleted = 0 nếu có)
  static Future<List<Genre>> getAll() async {
    try {
      final response = await Api.get(_endpoint);

      // ✅ Dữ liệu trả về có thể là Map hoặc List
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;

      final genres = (data as List)
          .map((e) => Genre.fromJson(e))
          .where((g) => g.isDeleted == 0) // lọc nếu có cột is_deleted
          .toList();

      return genres;
    } catch (e, s) {
      print("❌ [GenreService] Lỗi tải thể loại: $e\n$s");
      rethrow;
    }
  }

  /// 🔹 Lấy thể loại theo ID
  static Future<Genre?> getById(int id) async {
    try {
      final response = await Api.get("$_endpoint/$id");
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;

      final genre = Genre.fromJson(data);
      return genre.isDeleted == 1 ? null : genre; // tránh trả về bản ghi đã xóa
    } catch (e, s) {
      print("❌ [GenreService] Lỗi tải thể loại ID=$id: $e\n$s");
      rethrow;
    }
  }

  /// 🔹 Tạo mới thể loại
  static Future<bool> create(Genre genre) async {
    try {
      final response = await Api.post(_endpoint, genre.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, s) {
      print("❌ [GenreService] Lỗi thêm thể loại: $e\n$s");
      return false;
    }
  }

  /// 🔹 Cập nhật thể loại
  static Future<bool> update(int id, Genre genre) async {
    try {
      final response = await Api.put("$_endpoint/$id", genre.toJson());
      return response.statusCode == 200;
    } catch (e, s) {
      print("❌ [GenreService] Lỗi cập nhật thể loại ID=$id: $e\n$s");
      return false;
    }
  }

  /// 🔹 Xóa thể loại (logic delete hoặc hard delete)
  static Future<bool> delete(int id) async {
    try {
      final response = await Api.delete("$_endpoint/$id");
      return response.statusCode == 200;
    } catch (e, s) {
      print("❌ [GenreService] Lỗi xóa thể loại ID=$id: $e\n$s");
      return false;
    }
  }
}
