import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';

class PaymentService {
  //  Gọi API tạo thanh toán Premium
  static Future<String?> createPremiumPayment({
    required int accountId,
    required int amount,
    required int months,
  }) async {
    try {
      final res = await Api.post(
        "payments/create",
        {
          "accountId": accountId,
          "amount": amount,
          "months": months,
        },
      );

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);

      if (data is Map && data["paymentUrl"] != null) {
        return data["paymentUrl"];
      }

      return null;
    } on DioException catch (e) {
      print(" Lỗi tạo thanh toán Premium: ${e.message}");
      return null;
    }
  }

  //  Lấy lịch sử thanh toán Premium
  static Future<List<dynamic>> getPremiumHistory(int accountId) async {
    try {
      final res = await Api.get(
        "payments/history/$accountId",
      );

      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);

      if (data is Map && data["success"] == true) {
        return (data["data"] ?? []) as List<dynamic>;
      }

      return [];
    } on DioException catch (e) {
      print(" Lỗi load lịch sử Premium: ${e.message}");
      return [];
    } catch (e) {
      print(" Lỗi không xác định khi load history: $e");
      return [];
    }
  }
}
