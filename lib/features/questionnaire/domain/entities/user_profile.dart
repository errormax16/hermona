import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String firstName;
  final int age;
  final double imc;
  final bool sopk;
  final bool acneFamilyHistory;
  final bool smoker;
  final int cigarettesPerDay;
  final String alcohol;
  final String skinType;
  final List<String> cosmeticAllergies;
  final String hormonalTreatment;
  final String acneTreatment;
  final List<String> skincareRoutine;
  final DateTime lastPeriodsDate;
  final List<int> lastCyclesDuration;
  final Map<String, String> initialPhotos;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.age,
    required this.imc,
    required this.sopk,
    required this.acneFamilyHistory,
    required this.smoker,
    required this.cigarettesPerDay,
    required this.alcohol,
    required this.skinType,
    required this.cosmeticAllergies,
    required this.hormonalTreatment,
    required this.acneTreatment,
    required this.skincareRoutine,
    required this.lastPeriodsDate,
    required this.lastCyclesDuration,
    required this.initialPhotos,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      firstName: json['firstName'] ?? '',
      age: json['age'] ?? 0,
      imc: (json['imc'] ?? 0).toDouble(),
      sopk: json['sopk'] ?? false,
      acneFamilyHistory: json['acneFamilyHistory'] ?? false,
      smoker: json['smoker'] ?? false,
      cigarettesPerDay: json['cigarettesPerDay'] ?? 0,
      alcohol: json['alcohol'] ?? '',
      skinType: json['skinType'] ?? '',
      cosmeticAllergies: List<String>.from(json['cosmeticAllergies'] ?? []),
      hormonalTreatment: json['hormonalTreatment'] ?? '',
      acneTreatment: json['acneTreatment'] ?? '',
      skincareRoutine: List<String>.from(json['skincareRoutine'] ?? []),
      lastPeriodsDate: json['lastPeriodsDate'] is Timestamp
      ? (json['lastPeriodsDate'] as Timestamp).toDate()
      : DateTime.now(),
      lastCyclesDuration: List<int>.from(json['lastCyclesDuration'] ?? []),
      initialPhotos: json['initialPhotos'] != null
    ? Map<String, String>.from(json['initialPhotos'])
    : <String, String>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'age': age,
      'imc': imc,
      'sopk': sopk,
      'acneFamilyHistory': acneFamilyHistory,
      'smoker': smoker,
      'cigarettesPerDay': cigarettesPerDay,
      'alcohol': alcohol,
      'skinType': skinType,
      'cosmeticAllergies': cosmeticAllergies,
      'hormonalTreatment': hormonalTreatment,
      'acneTreatment': acneTreatment,
      'skincareRoutine': skincareRoutine,
      'lastPeriodsDate': Timestamp.fromDate(lastPeriodsDate),
      'lastCyclesDuration': lastCyclesDuration,
      'initialPhotos': initialPhotos,
    };
  }
}
