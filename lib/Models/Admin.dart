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
      totalEvents: json['total_events'],
      totalUsers: json['total_users'],
      totalBookings: json['total_bookings'],
      totalRevenue: double.parse(json['total_revenue'].toString()),
    );
  }
}