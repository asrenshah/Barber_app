// lib/models/barber_model.dart
import 'dart:convert';

class Barber {
  String id;
  String name;
  String? photoUrl;
  List<String> specialties;
  int experienceYears;
  double rating;
  int totalCustomers;
  bool isActive;
  int currentQueue;
  DateTime? lastAssigned;
  
  Barber({
    required this.id,
    required this.name,
    this.photoUrl,
    this.specialties = const ['Haircut', 'Shaving'],
    this.experienceYears = 1,
    this.rating = 4.5,
    this.totalCustomers = 0,
    this.isActive = true,
    this.currentQueue = 0,
    this.lastAssigned,
  });
  
  factory Barber.fromMap(Map<String, dynamic> data, String id) {
    return Barber(
      id: id,
      name: data['name'] ?? 'Unknown',
      photoUrl: data['photoUrl'],
      specialties: List<String>.from(data['specialties'] ?? ['Haircut']),
      experienceYears: data['experienceYears'] ?? 1,
      rating: (data['rating'] ?? 4.5).toDouble(),
      totalCustomers: data['totalCustomers'] ?? 0,
      isActive: data['isActive'] ?? true,
      currentQueue: data['currentQueue'] ?? 0,
      lastAssigned: data['lastAssigned']?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'specialties': specialties,
      'experienceYears': experienceYears,
      'rating': rating,
      'totalCustomers': totalCustomers,
      'isActive': isActive,
      'currentQueue': currentQueue,
      'lastAssigned': lastAssigned,
      'updatedAt': DateTime.now(),
    };
  }
  
  String toJson() => json.encode(toMap());
  
  factory Barber.fromJson(String source) => 
      Barber.fromMap(json.decode(source), 'temp');
}