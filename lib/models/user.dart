import 'package:cloud_firestore/cloud_firestore.dart';

abstract class User {
  final String? uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profilePictureUrl;
  final DateTime registrationDate;
  final bool isVerified;

  User({
    this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profilePictureUrl,
    DateTime? registrationDate,
    this.isVerified = false,
  }) : registrationDate = registrationDate ?? DateTime.now();

  Map<String, dynamic> toMap();

  factory User.fromMap(Map<String, dynamic> map, String type) {
    if (type == 'student') {
      // Implémenter Student.fromMap
      throw UnimplementedError();
    } else if (type == 'owner') {
      // Implémenter Owner.fromMap
      throw UnimplementedError();
    } else {
      throw ArgumentError('Invalid user type: $type');
    }
  }

  // Méthode abstraite pour déterminer le type d'utilisateur
  String getUserType();
}