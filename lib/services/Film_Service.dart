import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Film_info.dart';

class FilmService {
  static const String _endpoint = "/films";

  /// ============================================================
  /// 🔥 FIX QUAN TRỌNG: Trích xuất đúng mảng phim từ API
  /// ============================================================
  static dynamic _extractData(Response response) {
    final res = response.data;

    // TH1: API trả thẳng List
    if (res is List) return res;

    // TH2: API trả Map
    if (res is Map<String, dynamic>) {
      // Ưu tiên key "data"
      if (res.containsKey('data')) return res['data'];

      // Key phổ biến
      for (final key in ["result", "results", "films", "items", "list"]) {
        if (res.containsKey(key)) return res[key];
      }

      // TH3: API trả object film (không phải list)
      // → dành cho chi tiết phim
      return res;
    }

    // fallback
    return res;
  }

  // ---------------------------------------------------
  // 🔹 Lấy tất cả phim
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getAllFilms() async {
    try {
      final response = await Api.get(_endpoint);
      final data = _extractData(response);

      return List<FilmInfo>.from(
        (data as List).map((e) => FilmInfo.fromJson(e)),
      );
    } catch (e) {
      throw Exception("❌ Lỗi khi tải danh sách phim: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Lấy phim theo ID (route cũ)
  // ---------------------------------------------------
  static Future<FilmInfo> getFilmById(int id) async {
    try {
      final response = await Api.get("$_endpoint/$id");
      final data = _extractData(response);
      return FilmInfo.fromJson(data);
    } catch (e) {
      throw Exception("❌ Lỗi khi tải phim có ID $id: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Lấy chi tiết phim (route mới `/films/detail/:id`)
  // ---------------------------------------------------
  static Future<FilmInfo> getFilmDetail(int id) async {
    try {
      final response = await Api.get("$_endpoint/detail/$id");
      final data = _extractData(response);

      if (data == null) throw Exception("Không có dữ liệu phim");

      return FilmInfo.fromJson(data);
    } catch (e) {
      throw Exception("❌ Lỗi khi tải chi tiết phim ID $id: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Lấy phim cho trang Home
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getHomeFilms() async {
    try {
      final response = await Api.get("$_endpoint/home");
      final data = _extractData(response);

      print("🔥 DEBUG — HomeFilms length: ${(data as List).length}");

      return List<FilmInfo>.from(
        data.map((e) => FilmInfo.fromJson(e)),
      );
    } catch (e) {
      throw Exception("❌ Lỗi khi tải dữ liệu trang Home: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Tìm kiếm phim
  // ---------------------------------------------------
  static Future<List<FilmInfo>> searchFilms(String keyword) async {
    try {
      final response = await Api.get(
        "$_endpoint/search",
        query: {'keyword': keyword},
      );

      final data = _extractData(response);

      return List<FilmInfo>.from(
        (data as List).map((e) => FilmInfo.fromJson(e)),
      );
    } catch (e) {
      throw Exception("❌ Lỗi khi tìm kiếm phim: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Lấy toàn bộ phim cho Kho phim
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getSearchFilms() async {
    try {
      final response = await Api.get("$_endpoint/find/all");
      final data = _extractData(response);

      return List<FilmInfo>.from(
        (data as List).map((e) => FilmInfo.fromJson(e)),
      );
    } catch (e) {
      throw Exception("❌ Lỗi khi tải danh sách phim kho phim: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Phim đề xuất
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getRecommendations(
      String countryName, int excludeId,
      {String? genres}) async {
    try {
      final query = {
        'countryName': countryName,
        'excludeFilmId': excludeId.toString(),
      };

      if (genres != null && genres.isNotEmpty) {
        query['genres'] = genres;
      }

      final response = await Api.get(
        "$_endpoint/recommendations",
        query: query,
      );

      final data = _extractData(response);

      return List<FilmInfo>.from(
        (data as List).map((e) => FilmInfo.fromJson(e)),
      );
    } catch (e) {
      throw Exception("❌ Lỗi khi tải danh sách phim đề xuất: $e");
    }
  }
}
