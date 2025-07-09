class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? password; // Only for registration
  final DateTime? createdAt;

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
    // Handle both string and int IDs from API
    final id = json['id'] is String
        ? int.tryParse(json['id']) ?? 0
        : json['id'] as int? ?? 0;

    // Parse date with fallback
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return User(
      id: id,
      fullName: json['full_name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      if (password != null) 'password': password,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, role: $role)';
  }
}