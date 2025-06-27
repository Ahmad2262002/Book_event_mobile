// models/AdminStats.dart
class AdminStats {
  final int totalEvents;
  final int totalUsers;
  final int totalBookings;
  final double totalRevenue;

  AdminStats({
    required this.totalEvents,
    required this.totalUsers,
    required this.totalBookings,
    required this.totalRevenue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalEvents: json['total_events'] as int,
      totalUsers: json['total_users'] as int,
      totalBookings: json['total_bookings'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
    );
  }
}