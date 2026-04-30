import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String firstName;
  final List<String> cosmeticAllergies;
  final List<String> skincareRoutine;
  final List<int> lastCyclesDuration;
  final Map<String, String> initialPhotos;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.cosmeticAllergies,
    required this.skincareRoutine,
    required this.lastCyclesDuration,
    required this.initialPhotos,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      firstName: json['firstName'] ?? '',
      cosmeticAllergies: List<String>.from(json['cosmeticAllergies'] ?? []),
      skincareRoutine: List<String>.from(json['skincareRoutine'] ?? []),
      lastCyclesDuration: List<int>.from(json['lastCyclesDuration'] ?? []),
      initialPhotos: json['initialPhotos'] != null
    ? Map<String, String>.from(json['initialPhotos'])
    : <String, String>{},
    );
  }
}

void main() {
  final Map<String, dynamic> newUserJson = {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "photoUrl": null,
    "createdAt": "2023-01-01T00:00:00.000",
    "termsAccepted": true
  };

  try {
    final profile = UserProfile.fromJson(newUserJson, "123");
    print("UserProfile parsed successfully: ${profile.firstName}");
    
    // Simulate what happens in _populate:
    List<String> ca = List<String>.from(profile.cosmeticAllergies);
    print("Cosmetic allergies populated: $ca");
    
  } catch (e, stack) {
    print("Error during parsing:");
    print(e);
    print(stack);
  }
}
