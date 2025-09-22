import 'package:cloud_firestore/cloud_firestore.dart';

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

  // 🔹 Convert to Firestore map (without the 'id' field)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'profileImagePath': profileImagePath,
    };
  }

  // 🔹 Create from a Firestore Document Snapshot
  factory Traveller.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Traveller(
      id: doc.id,
      name: data['name'] as String? ?? '',
      contact: data['contact'] as String?,
      profileImagePath: data['profileImagePath'] as String?,
    );
  }
}