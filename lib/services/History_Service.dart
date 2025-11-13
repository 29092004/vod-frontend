import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/History.dart';
import '../config/api.dart';

class HistoryService {
  // 🔹 Lấy danh sách phim đang xem tiếp
  static Future<List<History>> getContinueWatching(int profileId) async {
    final rawUrl = '${Api.baseUrl}/history/continue/$profileId';
    final fixedUrl = rawUrl.replaceAll('//', '/').replaceFirst('https:/', 'https://');
    print("📡 [HISTORY] Gửi request lấy danh sách xem tiếp");
    print("➡ URL: $fixedUrl");

    final url = Uri.parse(fixedUrl);
    final response = await http.get(url);

    print("📩 [HISTORY] Phản hồi server:");
    print("➡ STATUS: ${response.statusCode}");
    print("➡ BODY: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list.map((e) => History.fromJson(e)).toList();
    } else {
      print("❌ [HISTORY] Lỗi khi tải danh sách xem tiếp: ${response.statusCode}");
      throw Exception('Failed to load continue watching');
    }
  }

  // 🔹 Cập nhật tiến độ xem
  static Future<void> updateProgress({
    required int profileId,
    required int filmId,
    required int episodeId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final rawUrl = '${Api.baseUrl}/history/progress';
    final fixedUrl = rawUrl.replaceAll('//', '/').replaceFirst('https:/', 'https://');
    print("📡 [HISTORY] Gửi request lưu tiến độ xem");
    print("➡ URL: $fixedUrl");

    try {
      final url = Uri.parse(fixedUrl);
      final body = jsonEncode({
        'profile_id': profileId,
        'film_id': filmId,
        'episode_id': episodeId,
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
      });
      print("➡ BODY gửi: $body");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("📩 [HISTORY] Phản hồi server:");
      print("➡ STATUS: ${response.statusCode}");
      print("➡ BODY: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("❌ [HISTORY] Lỗi lưu tiến độ xem");
        throw Exception('Failed to update watch progress');
      }

      print("✅ [HISTORY] Cập nhật tiến độ xem thành công!");
    } catch (e) {
      print("❌ [HISTORY] Exception khi gửi request: $e");
      throw Exception('Failed to update watch progress');
    }
  }

  static Future<void> deleteHistory(int historyId) async {
    final rawUrl = '${Api.baseUrl}/history/$historyId';
    // ✅ Chuẩn hoá URL để tránh // bị lặp
    final fixedUrl = rawUrl.replaceAll('//', '/').replaceFirst('https:/', 'https://');

    print('🗑 [HISTORY] DELETE: $fixedUrl');

    final url = Uri.parse(fixedUrl);
    final response = await http.delete(url);

    print('📩 STATUS: ${response.statusCode}');
    print('📩 BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete history');
    }
  }
}
