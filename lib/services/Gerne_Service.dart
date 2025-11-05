import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Genre.dart';

class GenreService {
  static final Dio _dio = Api.client;
  static const String _endpoint = "/genre";

  /// 🔹 Lấy tất cả thể loại
  static Future<List<Genre>> getAll() async {
    try {
      final response = await _dio.get(_endpoint);
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return List<Genre>.from((data as List).map((item) => Genre.fromJson(item)));
      } else {
        throw Exception("Không thể tải danh sách thể loại (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Lỗi tải danh sách thể loại: $e");
    }
  }

  /// 🔹 Lấy thể loại theo ID
  static Future<Genre?> getById(int id) async {
    try {
      final response = await _dio.get("$_endpoint/$id");
      if (response.statusCode == 200) {
        return Genre.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception("Lỗi tải thể loại theo ID: $e");
    }
  }

  /// 🔹 Thêm thể loại mới
  static Future<bool> create(Genre genre) async {
    try {
      final response = await _dio.post(_endpoint, data: genre.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception("Lỗi thêm thể loại: $e");
    }
  }

  /// 🔹 Cập nhật thể loại
  static Future<bool> update(int id, Genre genre) async {
    try {
      final response = await _dio.put("$_endpoint/$id", data: genre.toJson());
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi cập nhật thể loại: $e");
    }
  }

  /// 🔹 Xóa thể loại
  static Future<bool> delete(int id) async {
    try {
      final response = await _dio.delete("$_endpoint/$id");
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi xóa thể loại: $e");
    }
  }
}
