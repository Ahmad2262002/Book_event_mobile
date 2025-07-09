import 'package:intl/intl.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String image;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.image,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date']?.toString() ?? DateTime.now().toString()),
      endDate: DateTime.parse(json['end_date']?.toString() ?? DateTime.now().toString()),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      totalSeats: int.tryParse(json['total_seats']?.toString() ?? '0') ?? 0,
      availableSeats: int.tryParse(json['available_seats']?.toString() ?? '0') ?? 0,
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate),
      'price': price,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'image': image,
    };
  }
}