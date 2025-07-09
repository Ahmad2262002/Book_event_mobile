
class Booking {
  final int id;
  final int userId;
  final int eventId;
  final String status;
  final DateTime bookingDate;
  final String paymentStatus;
  final String qrCode;
  final String? eventTitle;
  final DateTime? startDate;
  final String? location;
  final double? price;
  // New fields for admin view
  final String? userName;
  final String? userEmail;


  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.bookingDate,
    required this.paymentStatus,
    required this.qrCode,
    this.eventTitle,
    this.startDate,
    this.location,
    this.price,
    this.userName,
    this.userEmail,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      eventId: int.parse(json['event_id'].toString()),
      status: json['status']?.toString() ?? 'pending',
      bookingDate: DateTime.parse(json['booking_date'].toString()),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      qrCode: json['qr_code']?.toString() ?? '',
      eventTitle: json['event_title']?.toString(),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'].toString())
          : null,
      location: json['location']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0
          : null,
      // Parse new fields (will be null for regular users)
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status,
      'booking_date': bookingDate.toIso8601String(),
      'payment_status': paymentStatus,
      'qr_code': qrCode,
      if (eventTitle != null) 'event_title': eventTitle,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (location != null) 'location': location,
      if (price != null) 'price': price,
    };
  }
}