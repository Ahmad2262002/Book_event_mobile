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
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      price: double.parse(json['price']),
      totalSeats: int.parse(json['total_seats']),
      availableSeats: int.parse(json['available_seats']),
      image: json['image'],
    );
  }
}