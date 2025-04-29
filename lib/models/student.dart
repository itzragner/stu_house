import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'application.dart';

class Student extends User {
  final String? universityName;
  final String? studentId;
  final DateTime? endOfStudies;
  final List<String> favoritePropertyIds;
  final List<RentalApplication> applications;

  Student({
    String? uid,
    required String email,
    required String fullName,
    required String phoneNumber,
    String? profilePictureUrl,
    this.universityName,
    this.studentId,
    this.endOfStudies,
    List<String>? favoritePropertyIds,
    List<RentalApplication>? applications,
    DateTime? registrationDate,
    bool isVerified = false,
  }) :
        favoritePropertyIds = favoritePropertyIds ?? [],
        applications = applications ?? [],
        super(
        uid: uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        profilePictureUrl: profilePictureUrl,
        registrationDate: registrationDate,
        isVerified: isVerified,
      );

  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'registrationDate': registrationDate,
      'isVerified': isVerified,
      'userType': 'student',
      'universityName': universityName,
      'studentId': studentId,
      'endOfStudies': endOfStudies,
      'favoritePropertyIds': favoritePropertyIds,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String uid) {
    return Student(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      registrationDate: (map['registrationDate'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      universityName: map['universityName'],
      studentId: map['studentId'],
      endOfStudies: (map['endOfStudies'] as Timestamp?)?.toDate(),
      favoritePropertyIds: List<String>.from(map['favoritePropertyIds'] ?? []),
    );
  }

  @override
  String getUserType() => 'student';

  // Méthode pour ajouter un logement aux favoris
  Student addFavoriteProperty(String propertyId) {
    if (!favoritePropertyIds.contains(propertyId)) {
      List<String> newFavorites = List.from(favoritePropertyIds)
        ..add(propertyId);
      return copyWith(favoritePropertyIds: newFavorites);
    }
    return this;
  }

  // Méthode pour retirer un logement des favoris
  Student removeFavoriteProperty(String propertyId) {
    if (favoritePropertyIds.contains(propertyId)) {
      List<String> newFavorites = List.from(favoritePropertyIds)
        ..remove(propertyId);
      return copyWith(favoritePropertyIds: newFavorites);
    }
    return this;
  }

  // Méthode pour créer une copie avec des modifications
  Student copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
    String? universityName,
    String? studentId,
    DateTime? endOfStudies,
    List<String>? favoritePropertyIds,
    List<RentalApplication>? applications,
    DateTime? registrationDate,
    bool? isVerified,
  }) {
    return Student(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      universityName: universityName ?? this.universityName,
      studentId: studentId ?? this.studentId,
      endOfStudies: endOfStudies ?? this.endOfStudies,
      favoritePropertyIds: favoritePropertyIds ?? this.favoritePropertyIds,
      applications: applications ?? this.applications,
      registrationDate: registrationDate ?? this.registrationDate,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}