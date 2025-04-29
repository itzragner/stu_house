// models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Review {
  final String reviewId;
  final String propertyId;
  final String studentId;
  final String ownerId;
  final double rating;
  final String comment;
  final DateTime reviewDate;
  final String? studentName;
  final String? studentPhotoUrl;

  Review({
    String? reviewId,
    required this.propertyId,
    required this.studentId,
    required this.ownerId,
    required this.rating,
    required this.comment,
    DateTime? reviewDate,
    this.studentName,
    this.studentPhotoUrl,
  }) :
        reviewId = reviewId ?? const Uuid().v4(),
        reviewDate = reviewDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'propertyId': propertyId,
      'studentId': studentId,
      'ownerId': ownerId,
      'rating': rating,
      'comment': comment,
      'reviewDate': reviewDate,
      'studentName': studentName,
      'studentPhotoUrl': studentPhotoUrl,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      reviewId: map['reviewId'],
      propertyId: map['propertyId'] ?? '',
      studentId: map['studentId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      reviewDate: (map['reviewDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentName: map['studentName'],
      studentPhotoUrl: map['studentPhotoUrl'],
    );
  }

  Review copyWith({
    String? reviewId,
    String? propertyId,
    String? studentId,
    String? ownerId,
    double? rating,
    String? comment,
    DateTime? reviewDate,
    String? studentName,
    String? studentPhotoUrl,
  }) {
    return Review(
      reviewId: reviewId ?? this.reviewId,
      propertyId: propertyId ?? this.propertyId,
      studentId: studentId ?? this.studentId,
      ownerId: ownerId ?? this.ownerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewDate: reviewDate ?? this.reviewDate,
      studentName: studentName ?? this.studentName,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
    );
  }
}




