import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'property.dart';
import 'application.dart';
import 'review.dart';

class Owner extends User {
  final String? identityVerificationDoc;
  final bool isVerifiedOwner;
  final List<Property> properties;
  final List<RentalApplication> receivedApplications;
  final double rating;
  final List  <Review> reviews;

  Owner({
    String? uid,
    required String email,
    required String fullName,
    required String phoneNumber,
    String? profilePictureUrl,
    this.identityVerificationDoc,
    this.isVerifiedOwner = false,
    List<Property>? properties,
    List<RentalApplication>? receivedApplications,
    this.rating = 0.0,
    List<Review>? reviews,
    DateTime? registrationDate,
    bool isVerified = false,
  }) :
        properties = properties ?? [],
        receivedApplications = receivedApplications ?? [],
        reviews = reviews ?? [],
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
      'userType': 'owner',
      'identityVerificationDoc': identityVerificationDoc,
      'isVerifiedOwner': isVerifiedOwner,
      'rating': rating,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map, String uid) {
    return Owner(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      registrationDate: (map['registrationDate'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      identityVerificationDoc: map['identityVerificationDoc'],
      isVerifiedOwner: map['isVerifiedOwner'] ?? false,
      rating: map['rating']?.toDouble() ?? 0.0,
    );
  }

  @override
  String getUserType() => 'owner';

  // Méthode pour créer une copie avec des modifications
  Owner copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
    String? identityVerificationDoc,
    bool? isVerifiedOwner,
    List<Property>? properties,
    List<RentalApplication>? receivedApplications,
    double? rating,
    List<Review>? reviews,
    DateTime? registrationDate,
    bool? isVerified,
  }) {
    return Owner(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      identityVerificationDoc: identityVerificationDoc ?? this.identityVerificationDoc,
      isVerifiedOwner: isVerifiedOwner ?? this.isVerifiedOwner,
      properties: properties ?? this.properties,
      receivedApplications: receivedApplications ?? this.receivedApplications,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      registrationDate: registrationDate ?? this.registrationDate,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}