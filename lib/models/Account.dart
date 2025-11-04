class Account {
  final int accountId;
  final String email;
  final String password;
  final String role;

  Account({
    required this.accountId,
    required this.email,
    required this.password,
    required this.role,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['Account_id'] is int
          ? json['Account_id']
          : int.tryParse(json['Account_id'].toString()) ?? 0,
      email: json['Email'] ?? '',
      password: json['Password'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Account_id': accountId,
    'Email': email,
    'Password': password,
    'role': role,
  };
}
