class Testimonial {
  final int id;
  final int userId;
  final String userName;
  final String content;
  final bool isApproved;
  final DateTime createdAt;

  Testimonial({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.isApproved,
    required this.createdAt,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      content: json['content'],
      isApproved: json['is_approved'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'content': content,
    };
  }
}