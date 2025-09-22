class Trip {
  final String id;
  final String title;
  final String subtitle;
  final String origin;
  final String destination;
  final DateTime startTime;
  final DateTime endTime;
  final String transportMode;
  final String notes;
  final String? coverImagePath;

  // 👇 Add this
  final List<String> travellerIds;

  Trip({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.origin,
    required this.destination,
    required this.startTime,
    required this.endTime,
    required this.transportMode,
    required this.notes,
    this.coverImagePath,
    this.travellerIds = const [], // 👈 default empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'origin': origin,
      'destination': destination,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'transportMode': transportMode,
      'notes': notes,
      'coverImagePath': coverImagePath,
      'travellerIds': travellerIds, // 👈 save it
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map, String docId) {
    print("DEBUG Trip.fromMap: $map");
    return Trip(
      id: docId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      transportMode: map['transportMode'] ?? '',
      notes: map['notes'] ?? '',
      coverImagePath: map['coverImagePath'],
      travellerIds: List<String>.from(map['travellerIds'] ?? []),
    );
  }

}
class Traveller {
  final String id;
  final String name;
  final String? contact;
  final String? profileImagePath;

  Traveller({
    required this.id,
    required this.name,
    this.contact,
    this.profileImagePath,
  });

  factory Traveller.fromMap(String id, Map<String, dynamic> data) {
    return Traveller(
      id: id,
      name: data['name'] ?? '',
      contact: data['contact'],
      profileImagePath: data['profileImagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'profileImagePath': profileImagePath,
    };
  }
}
