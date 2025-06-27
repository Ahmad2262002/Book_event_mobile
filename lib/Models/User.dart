class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? password; // Only for registration/
  final String? createdAt;


  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.password,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt,
      if (password != null) 'password': password,
    };
  }
}