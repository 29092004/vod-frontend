import 'package:dio/dio.dart';
import '../config/api.dart';

class ActorService {
  /// Lấy chi tiết diễn viên
  static Future<Map<String, dynamic>?> getActorById(int actorId) async {
    try {
      final res = await Api.get('actors/$actorId');
      if (res.data['success'] == true) {
        return res.data['data'];
      }
      return null;
    } catch (e) {
      print("Error getActorById: $e");
      return null;
    }
  }

  /// Lấy danh sách phim diễn viên đã đóng
  static Future<List<Map<String, dynamic>>> getFilmsByActor(int actorId) async {
    try {
      final res = await Api.get('actors/$actorId/films');
      if (res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
      return [];
    } catch (e) {
      print("Error getFilmsByActor: $e");
      return [];
    }
  }
}
