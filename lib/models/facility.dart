class Facility {
  final String id;
  final String name;
  final String sport;
  final String location;
  final String description;
  final List<String> amenities;

  /// Start hours (24h) of the one-hour slots offered each day.
  final List<int> slotHours;

  /// Price in rupees for one hour.
  final int pricePerHour;

  const Facility({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
    required this.description,
    required this.amenities,
    required this.slotHours,
    this.pricePerHour = 200,
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as String,
        name: json['name'] as String,
        sport: json['sport'] as String,
        location: json['location'] as String,
        description: json['description'] as String,
        amenities: List<String>.from(json['amenities'] as List),
        slotHours: List<int>.from(json['slotHours'] as List),
        pricePerHour: json['pricePerHour'] as int? ?? 200,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sport': sport,
        'location': location,
        'description': description,
        'amenities': amenities,
        'slotHours': slotHours,
        'pricePerHour': pricePerHour,
      };
}
