import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEntity extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final bool termsAccepted;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.termsAccepted,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  factory UserEntity.fromJson(Map<String, dynamic> j, String id) {
    DateTime d;
    if (j['createdAt'] is Timestamp) {
      d = (j['createdAt'] as Timestamp).toDate();
    } else if (j['createdAt'] is String) {
      d = DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now();
    } else {
      d = DateTime.now();
    }
    return UserEntity(
      id           : id,
      firstName    : j['firstName']    as String? ?? '',
      lastName     : j['lastName']     as String? ?? '',
      email        : j['email']        as String? ?? '',
      photoUrl     : j['photoUrl']     as String?,
      createdAt    : d,
      termsAccepted: j['termsAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName'    : firstName,
    'lastName'     : lastName,
    'email'        : email,
    'photoUrl'     : photoUrl,
    'createdAt'    : createdAt.toIso8601String(),
    'termsAccepted': termsAccepted,
  };

  @override
  List<Object?> get props => [id, email];
}
