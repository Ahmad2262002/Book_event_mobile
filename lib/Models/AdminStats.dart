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
    // Helper functions for safe parsing
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AdminStats(
      totalEvents: parseInt(json['total_events']),
      totalUsers: parseInt(json['total_users']),
      totalBookings: parseInt(json['total_bookings']),
      totalRevenue: parseDouble(json['total_revenue']),
    );
  }

  @override
  String toString() {
    return 'AdminStats(totalEvents: $totalEvents, totalUsers: $totalUsers, '
        'totalBookings: $totalBookings, totalRevenue: $totalRevenue)';
  }
}