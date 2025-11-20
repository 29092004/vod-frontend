class PaymentHistory {
  final int id;
  final int amount;
  final String method;
  final DateTime paidAt;
  final DateTime expiredAt;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.expiredAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json["id"] ?? 0,
      amount: json["amount"] ?? 0,
      method: json["method"] ?? "vnpay",
      paidAt: DateTime.parse(json["paid_at"]),
      expiredAt: DateTime.parse(json["expired_at"]),
    );
  }
}
