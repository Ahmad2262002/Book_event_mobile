class Testimonial {
  final int id;
  final int userId;
  final String userName;
  final String content;
  final bool approved;
  final DateTime createdAt;

  Testimonial({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.approved,
    required this.createdAt,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    // Handle both string and int IDs from API
    final id = json['id'] is String
        ? int.tryParse(json['id']) ?? 0
        : json['id'] as int? ?? 0;

    final userId = json['user_id'] is String
        ? int.tryParse(json['user_id']) ?? 0
        : json['user_id'] as int? ?? 0;

    // Handle different approved formats (string "0"/"1" or bool)
    bool approved;
    if (json['approved'] is bool) {
      approved = json['approved'];
    } else {
      approved = json['approved']?.toString() == '1';
    }

    // Parse date with fallback to current time
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Testimonial(
      id: id,
      userId: userId,
      userName: json['user_name']?.toString() ?? 'Anonymous',
      content: json['content']?.toString() ?? '',
      approved: approved,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'approved': approved ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Testimonial(id: $id, user: $userName, approved: $approved)';
  }
}