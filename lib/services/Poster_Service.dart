import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Poster.dart';

class PosterService {
  static final Dio _dio = Api.client;
  static const String _endpoint = "/poster";

  /// 🔹 Lấy toàn bộ danh sách poster
  static Future<List<Poster>> getAll() async {
    try {
      final response = await _dio.get(_endpoint);
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return List<Poster>.from(
            (data as List).map((item) => Poster.fromJson(item)));
      } else {
        throw Exception("Không thể tải danh sách poster (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Lỗi tải poster: $e");
    }
  }

  /// 🔹 Lấy poster theo ID
  static Future<Poster?> getById(int id) async {
    try {
      final response = await _dio.get("$_endpoint/$id");
      if (response.statusCode == 200) {
        return Poster.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception("Lỗi tải poster theo ID: $e");
    }
  }

  /// 🔹 Lấy danh sách poster theo Film_id
  static Future<List<Poster>> getByFilm(int filmId) async {
    try {
      final response = await _dio.get("$_endpoint/film/$filmId");
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return List<Poster>.from(
            (data as List).map((item) => Poster.fromJson(item)));
      } else {
        throw Exception("Không thể tải poster theo Film_id (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Lỗi tải poster theo Film_id: $e");
    }
  }

  /// 🔹 Thêm poster mới
  static Future<bool> create(Poster poster) async {
    try {
      final response = await _dio.post(_endpoint, data: poster.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception("Lỗi tạo poster: $e");
    }
  }

  /// 🔹 Cập nhật poster
  static Future<bool> update(int id, Poster poster) async {
    try {
      final response = await _dio.put("$_endpoint/$id", data: poster.toJson());
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi cập nhật poster: $e");
    }
  }

  /// 🔹 Xóa poster
  static Future<bool> delete(int id) async {
    try {
      final response = await _dio.delete("$_endpoint/$id");
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Lỗi xóa poster: $e");
    }
  }
}
