import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Film_info.dart';

class FilmService {
  static const String _endpoint = "/films";

  /// 🔹 Lấy tất cả phim
  static Future<List<FilmInfo>> getAllFilms() async {
    try {
      final response = await Api.get(_endpoint);
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return List<FilmInfo>.from((data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tải danh sách phim: $e");
    }
  }

  /// 🔹 Lấy phim theo ID
  static Future<FilmInfo> getFilmById(int id) async {
    try {
      final response = await Api.get("$_endpoint/$id");
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return FilmInfo.fromJson(data);
    } catch (e) {
      throw Exception("❌ Lỗi khi tải phim có ID $id: $e");
    }
  }

  /// 🔹 Lấy danh sách phim cho trang Home
  static Future<List<FilmInfo>> getHomeFilms() async {
    try {
      final response = await Api.get("$_endpoint/home");
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return List<FilmInfo>.from((data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tải dữ liệu trang Home: $e");
    }
  }

  /// 🔹 Tìm kiếm phim theo từ khóa
  static Future<List<FilmInfo>> searchFilms(String keyword) async {
    try {
      final response =
      await Api.get("$_endpoint/search", query: {'keyword': keyword});
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return List<FilmInfo>.from((data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tìm kiếm phim: $e");
    }
  }
}
