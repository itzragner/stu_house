import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum ApplicationStatus {
  pending,
  accepted,
  rejected
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  static ApplicationStatus fromString(String value) {
    return ApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => ApplicationStatus.pending,
    );
  }
}

class RentalApplication {
  final String applicationId;
  final String studentId;
  final String propertyId;
  final String message;
  final DateTime applicationDate;
  final ApplicationStatus status;
  final String? ownerResponse;

  RentalApplication({
    String? applicationId,
    required this.studentId,
    required this.propertyId,
    required this.message,
    DateTime? applicationDate,
    this.status = ApplicationStatus.pending,
    this.ownerResponse,
  }) :
        applicationId = applicationId ?? const Uuid().v4(),
        applicationDate = applicationDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'studentId': studentId,
      'propertyId': propertyId,
      'message': message,
      'applicationDate': applicationDate,
      'status': status.toString().split('.').last,
      'ownerResponse': ownerResponse,
    };
  }

  factory RentalApplication.fromMap(Map<String, dynamic> map) {
    return RentalApplication(
      applicationId: map['applicationId'],
      studentId: map['studentId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      message: map['message'] ?? '',
      applicationDate: (map['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ApplicationStatusExtension.fromString(map['status'] ?? 'pending'),
      ownerResponse: map['ownerResponse'],
    );
  }

  RentalApplication copyWith({
    String? applicationId,
    String? studentId,
    String? propertyId,
    String? message,
    DateTime? applicationDate,
    ApplicationStatus? status,
    String? ownerResponse,
  }) {
    return RentalApplication(
      applicationId: applicationId ?? this.applicationId,
      studentId: studentId ?? this.studentId,
      propertyId: propertyId ?? this.propertyId,
      message: message ?? this.message,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      ownerResponse: ownerResponse ?? this.ownerResponse,
    );
  }

  // Mettre à jour le statut de la candidature
  RentalApplication updateStatus(ApplicationStatus newStatus, String? response) {
    return copyWith(
      status: newStatus,
      ownerResponse: response,
    );
  }
}