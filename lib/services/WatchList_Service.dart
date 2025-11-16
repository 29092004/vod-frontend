import 'package:dio/dio.dart';
import '../models/watchlist.dart';
import '../config/api.dart'; // chỉnh lại đường dẫn nếu cần

class WatchListService {
  /// Lấy tất cả watchlist của 1 profile
  static Future<List<WatchList>> getByProfile(int profileId) async {
    await Api.loadToken();
    final res = await Api.get('/watchlists/profile/$profileId');

    final data = res.data;
    if (data is Map && data['success'] == true && data['data'] is List) {
      final List list = data['data'];
      return list
          .map((e) => WatchList.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Tạo watchlist mới
  static Future<WatchList?> createWatchList({
    required int profileId,
    required String name,
  }) async {
    await Api.loadToken();
    try {
      final res = await Api.post(
        '/watchlists',
        {'profile_id': profileId, 'watchlist_name': name},
      );

      final data = res.data;
      if (data is Map && data['success'] == true) {
        // Backend hiện chưa trả lại record mới, nên thường sẽ phải gọi lại getByProfile
        // Nếu sau này BE trả data, có thể parse trực tiếp ở đây.
        return null;
      }
      return null;
    } on DioException catch (e) {
      // Nếu bạn có Api.handleError thì có thể dùng:
      // final msg = Api.handleError(e);
      // throw Exception(msg);
      rethrow;
    }
  }
}
