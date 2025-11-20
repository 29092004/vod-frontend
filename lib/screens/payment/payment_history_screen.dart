import 'package:flutter/material.dart';
import '../../services/Payment_Service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int accountId;

  const PaymentHistoryScreen({super.key, required this.accountId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    history = await PaymentService.getPremiumHistory(widget.accountId);
    setState(() => loading = false);
  }

  String _fmt(String date) {
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Lịch sử thanh toán"),
      ),
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(
        child: Text(
          "Chưa có giao dịch",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final h = history[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Premium Membership",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  "Số tiền: ${h["Amount"]} đ",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                ),

                const SizedBox(height: 6),
                Text(
                  "Thanh toán qua: ${h["Method"]}",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 6),
                Text(
                  "Thanh toán: ${_fmt(h["Paid_at"])}",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 6),
                Text(
                  "Hết hạn: ${_fmt(h["Expired_at"])}",
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
