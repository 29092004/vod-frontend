import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/Film_info.dart';

class FilmService {
  final Dio _dio = Dio();
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? ''; // ✅ khớp với .env của bạn

  // ================================================================
  // 🔹 Lấy tất cả phim
  // ================================================================
  Future<List<FilmInfo>> getAllFilms() async {
    try {
      final String url = "${baseUrl}films"; // ✅ không thêm "/" vì env đã có rồi
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => FilmInfo.fromJson(e)).toList();
      } else {
        throw Exception('Không thể tải danh sách phim');
      }
    } catch (e) {
      throw Exception('❌ Lỗi khi tải phim: $e');
    }
  }

  // ================================================================
  // 🔹 Lấy phim theo ID
  // ================================================================
  Future<FilmInfo> getFilmById(int id) async {
    try {
      final String url = "${baseUrl}films/$id";
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return FilmInfo.fromJson(response.data['data']);
      } else {
        throw Exception('Không thể tải phim có ID $id');
      }
    } catch (e) {
      throw Exception('❌ Lỗi khi tải phim theo ID: $e');
    }
  }

  // ================================================================
  // 🔹 Lấy danh sách phim cho màn hình Home
  // ================================================================
  Future<List<FilmInfo>> getHomeFilms() async {
    try {
      final String url = "${baseUrl}films/home"; // ✅ đúng format
      print("🌐 Gọi API Home: $url"); // Debug log

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => FilmInfo.fromJson(e)).toList();
      } else {
        throw Exception('Phản hồi không hợp lệ từ server');
      }
    } catch (e) {
      throw Exception('❌ Lỗi khi tải dữ liệu trang Home: $e');
    }
  }

  // ================================================================
  // 🔹 Tìm kiếm phim theo từ khóa
  // ================================================================
  Future<List<FilmInfo>> searchFilms(String keyword) async {
    try {
      final String url = "${baseUrl}films/search";
      print("🔍 Gọi API Search: $url?keyword=$keyword"); // Debug log

      final response = await _dio.get(url, queryParameters: {'keyword': keyword});

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => FilmInfo.fromJson(e)).toList();
      } else {
        throw Exception('Không tìm thấy kết quả phù hợp');
      }
    } catch (e) {
      throw Exception('❌ Lỗi khi tìm kiếm phim: $e');
    }
  }
}
