import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/Film_info.dart';

class FilmService {
  static const String _endpoint = "/films";

  /// 🧩 Hàm tiện ích — trích xuất phần data từ response
  static dynamic _extractData(Response response) {
    final res = response.data;
    if (res is Map<String, dynamic>) {
      if (res.containsKey('data')) return res['data'];
      if (res.containsKey('result')) return res['result'];
    }
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
          (data as List).map((e) => FilmInfo.fromJson(e)));
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
      if (data == null) {
        throw Exception("Không có dữ liệu chi tiết cho phim ID $id");
      }

      // 🧩 Log ra thông tin phim & số lượng diễn viên để kiểm tra
      if (data is Map<String, dynamic>) {
        final filmName = data['Film_name'] ?? '(Không rõ)';
        final actorCount =
        (data['Actors'] is List) ? (data['Actors'] as List).length : 0;
        print("🎬 [Film Detail] $filmName — có $actorCount diễn viên");
      }

      // ✅ Parse về model FilmInfo (đã hỗ trợ Actors là mảng JSON)
      return FilmInfo.fromJson(data);
    } catch (e) {
      throw Exception("❌ Lỗi khi tải chi tiết phim ID $id: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Lấy danh sách phim cho trang Home
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getHomeFilms() async {
    try {
      final response = await Api.get("$_endpoint/home");
      final data = _extractData(response);

      return List<FilmInfo>.from(
          (data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tải dữ liệu trang Home: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Tìm kiếm phim theo từ khóa
  // ---------------------------------------------------
  static Future<List<FilmInfo>> searchFilms(String keyword) async {
    try {
      final response =
      await Api.get("$_endpoint/search", query: {'keyword': keyword});
      final data = _extractData(response);

      return List<FilmInfo>.from(
          (data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tìm kiếm phim: $e");
    }
  }

  // ---------------------------------------------------
  // 🔹 Trang "Kho phim" — lấy toàn bộ danh sách có chi tiết
  // ---------------------------------------------------
  static Future<List<FilmInfo>> getSearchFilms() async {
    try {
      final response = await Api.get("$_endpoint/find/all");
      final data = _extractData(response);

      return List<FilmInfo>.from(
          (data as List).map((e) => FilmInfo.fromJson(e)));
    } catch (e) {
      throw Exception("❌ Lỗi khi tải danh sách phim cho Kho phim: $e");
    }
  }

// ---------------------------------------------------
// 🔹 Lấy danh sách phim đề xuất cùng quốc gia & thể loại
// ---------------------------------------------------
  static Future<List<FilmInfo>> getRecommendations(String countryName,
      int excludeId, {String? genres}) async {
    try {
      // ✅ Tạo query parameters
      final Map<String, dynamic> queryParams = {
        'countryName': countryName,
        'excludeFilmId': excludeId.toString(),
      };

      // ✅ Nếu có danh sách thể loại thì thêm vào query (từ _film.genres)
      if (genres != null && genres.isNotEmpty) {
        queryParams['genres'] = genres;
      }

      // ✅ Gọi API
      final response = await Api.get(
        "$_endpoint/recommendations",
        query: queryParams,
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
