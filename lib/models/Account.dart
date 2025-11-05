class Account {
  final int accountId;
  final String email;
  final String role;

  Account({
    required this.accountId,
    required this.email,
    required this.role,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['Account_id'] is int
          ? json['Account_id']
          : int.tryParse(json['Account_id'].toString()) ?? 0,
      email: json['Email'] ?? '',
      role: json['role'] ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
    'Account_id': accountId,
    'Email': email,
    'role': role,
  };
}
