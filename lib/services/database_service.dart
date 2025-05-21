import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../models/student.dart';
import '../models/owner.dart';
import '../models/property.dart';
import '../models/application.dart';
import '../models/review.dart';
import '../services/storage_service.dart';
import 'mock_storage_service.dart';
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final MockStorageService _mockStorageService = MockStorageService();
  bool _useFirebaseStorage = true;
  // Collections
  final CollectionReference _usersCollection;
  final CollectionReference _studentsCollection;
  final CollectionReference _ownersCollection;
  final CollectionReference _propertiesCollection;
  final CollectionReference _applicationsCollection;
  final CollectionReference _reviewsCollection;
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');


  DatabaseService()
      : _usersCollection = FirebaseFirestore.instance.collection('users'),
        _studentsCollection = FirebaseFirestore.instance.collection('students'),
        _ownersCollection = FirebaseFirestore.instance.collection('owners'),
        _propertiesCollection = FirebaseFirestore.instance.collection(
            'properties'),
        _applicationsCollection = FirebaseFirestore.instance.collection(
            'applications'),
        _reviewsCollection = FirebaseFirestore.instance.collection('reviews');

  // *** NOTIF METHODS ***

  Future<String> createReviewWithNotification(Review review) async {
    try {
      print('Starting to create review: ${review.reviewId} for property: ${review.propertyId}');

      // 1. First, save the review without using a transaction
      await _reviewsCollection.doc(review.reviewId).set(review.toMap());
      print('Review document created successfully');

      // 2. Get property details for the notification
      Property? property;
      try {
        property = await getProperty(review.propertyId);
        print('Retrieved property: ${property.title}');
      } catch (e) {
        print('Error getting property: $e');
        throw Exception('Could not find the property');
      }

      // 3. Get student details
      String studentName = 'A student';
      String? studentPhotoUrl;

      try {
        final studentDoc = await _usersCollection.doc(review.studentId).get();
        if (studentDoc.exists) {
          final userData = studentDoc.data() as Map<String, dynamic>;
          studentName = userData['fullName'] ?? 'A student';
          studentPhotoUrl = userData['profilePictureUrl'];
          print('Retrieved student: $studentName');
        }
      } catch (e) {
        print('Error getting student info: $e');
        // Continue anyway, we have default values
      }

      // 4. Create notification for the owner
      final notification = Notification(
        userId: review.ownerId,
        title: 'New Review',
        message: '$studentName rated your property "${property.title}" ${review.rating} stars',
        type: NotificationType.newReview,
        relatedItemId: review.reviewId,
        relatedItemType: 'review',
        senderId: review.studentId,
        senderName: studentName,
        senderPhotoUrl: studentPhotoUrl,
      );

      await _notificationsCollection.doc(notification.notificationId).set(notification.toMap());
      print('Notification created successfully');

      // 5. Update property rating
      try {
        await updatePropertyRating(review.propertyId);
        print('Property rating updated successfully');
      } catch (e) {
        print('Error updating property rating: $e');
        // Continue anyway, the review is still created
      }

      return review.reviewId;
    } catch (e) {
      print('Detailed error in createReviewWithNotification: $e');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Notification>> getNotificationsForUser(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Notification.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<int?> getUnreadNotificationsCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }



  // *** IMAGE UPLOAD METHODS ***

  Future<String> uploadStudentImage(String studentId, File imageFile) async {
    try {
      if (_useFirebaseStorage) {
        try {
          return await _storageService.uploadProfilePicture(studentId, imageFile);
        } catch (e) {
          print('Firebase storage failed, using mock storage: $e');
          _useFirebaseStorage = false;
        }
      }

      // Fallback to mock storage
      return await _mockStorageService.uploadProfilePicture(studentId, imageFile);
    } catch (e) {
      print('Error uploading student image: $e');
      // Return a placeholder in case of error
      return 'https://via.placeholder.com/150?text=Student';
    }
  }

  Future<String> uploadOwnerImage(String ownerId, File imageFile, String type) async {
    try {
      if (_useFirebaseStorage) {
        try {
          if (type == 'profile') {
            return await _storageService.uploadProfilePicture(ownerId, imageFile);
          } else {
            return await _storageService.uploadIdentityDocument(ownerId, imageFile);
          }
        } catch (e) {
          print('Firebase storage failed, using mock storage: $e');
          _useFirebaseStorage = false;
        }
      }

      // Fallback to mock storage
      if (type == 'profile') {
        return await _mockStorageService.uploadProfilePicture(ownerId, imageFile);
      } else {
        return await _mockStorageService.uploadIdentityDocument(ownerId, imageFile);
      }
    } catch (e) {
      print('Error uploading owner image: $e');
      // Return a placeholder in case of error
      return 'https://via.placeholder.com/150?text=Owner';
    }
  }

  Future<String> uploadPropertyImage(String propertyId, File imageFile) async {
    try {
      if (_useFirebaseStorage) {
        try {
          return await _storageService.uploadPropertyImage(propertyId, imageFile);
        } catch (e) {
          print('Firebase storage failed, using mock storage: $e');
          _useFirebaseStorage = false;
        }
      }

      // Fallback to mock storage
      return await _mockStorageService.uploadPropertyImage(propertyId, imageFile);
    } catch (e) {
      print('Error uploading property image: $e');
      // Return a placeholder in case of error
      return 'https://via.placeholder.com/400x300?text=Property';
    }
  }

  // *** USER METHODS ***

  Future<String> getUserType(String uid) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();
      if (userDoc.exists) {
        return userDoc.get('userType') as String;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // *** STUDENT METHODS ***

  Future<void> createStudent(Student student) async {
    try {
      // First check if documents already exist
      final userDoc = await _usersCollection.doc(student.uid).get();
      final studentDoc = await _studentsCollection.doc(student.uid).get();

      // Batch write to ensure both documents are created/updated atomically
      WriteBatch batch = _db.batch();

      // Prepare user data
      Map<String, dynamic> userData = {
        'email': student.email,
        'fullName': student.fullName,
        'phoneNumber': student.phoneNumber,
        'registrationDate': student.registrationDate,
        'isVerified': student.isVerified,
        'userType': 'student',
      };

      // Add profilePictureUrl if it exists
      if (student.profilePictureUrl != null) {
        userData['profilePictureUrl'] = student.profilePictureUrl;
      }

      // Prepare student data
      Map<String, dynamic> studentData = {
        'favoritePropertyIds': student.favoritePropertyIds,
      };

      // Add optional fields if they exist
      if (student.universityName != null) {
        studentData['universityName'] = student.universityName;
      }
      if (student.studentId != null) {
        studentData['studentId'] = student.studentId;
      }
      if (student.endOfStudies != null) {
        studentData['endOfStudies'] = student.endOfStudies;
      }

      // Set or update the documents
      if (userDoc.exists) {
        batch.update(_usersCollection.doc(student.uid), userData);
      } else {
        batch.set(_usersCollection.doc(student.uid), userData);
      }

      if (studentDoc.exists) {
        batch.update(_studentsCollection.doc(student.uid), studentData);
      } else {
        batch.set(_studentsCollection.doc(student.uid), studentData);
      }

      // Commit the batch
      await batch.commit();

      print('Student created/updated successfully: ${student.uid}');
    } catch (e) {
      print('Error creating/updating student: $e');
      rethrow;
    }
  }

  Future<Student> getStudent(String uid) async {
    try {
      // Get basic user data
      DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();

      // Check if user exists
      if (!userDoc.exists) {
        print('User not found: $uid');
        throw Exception('User not found');
      }

      // Get student-specific data
      DocumentSnapshot studentDoc = await _studentsCollection.doc(uid).get();

      // Check if student exists
      if (!studentDoc.exists) {
        print('Student document not found. Creating default student document...');

        // Create default student document if it doesn't exist
        await _studentsCollection.doc(uid).set({
          'favoritePropertyIds': [],
        });

        // Re-fetch the student document
        studentDoc = await _studentsCollection.doc(uid).get();
      }

      // Combine data
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

      Map<String, dynamic> combinedData = {
        ...userData,
        ...studentData,
      };

      return Student.fromMap(combinedData, uid);
    } catch (e) {
      print('Error getting student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      // Mettre à jour les informations de base
      await _usersCollection.doc(student.uid).update({
        'fullName': student.fullName,
        'phoneNumber': student.phoneNumber,
        'profilePictureUrl': student.profilePictureUrl,
        'isVerified': student.isVerified,
      });

      // Mettre à jour les informations spécifiques à l'étudiant
      await _studentsCollection.doc(student.uid).update({
        'universityName': student.universityName,
        'studentId': student.studentId,
        'endOfStudies': student.endOfStudies,
        'favoritePropertyIds': student.favoritePropertyIds,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addFavoriteProperty(String studentId, String propertyId) async {
    try {
      await _studentsCollection.doc(studentId).update({
        'favoritePropertyIds': FieldValue.arrayUnion([propertyId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavoriteProperty(String studentId, String propertyId) async
  {
    try {
      await _studentsCollection.doc(studentId).update({
        'favoritePropertyIds': FieldValue.arrayRemove([propertyId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Property>> getFavoriteProperties(String studentId) async {
    try {
      // Obtenir d'abord la liste des IDs de propriétés favorites
      DocumentSnapshot studentDoc = await _studentsCollection
          .doc(studentId)
          .get();
      List<String> favoriteIds = List<String>.from(
          studentDoc.get('favoritePropertyIds') ?? []);

      if (favoriteIds.isEmpty) {
        return [];
      }

      // Récupérer les propriétés correspondantes
      List<Property> favoriteProperties = [];

      // Firebase ne permet pas de faire une requête whereIn avec plus de 10 éléments
      // Il faut donc faire des lots de 10 maximum
      for (int i = 0; i < favoriteIds.length; i += 10) {
        final end = (i + 10 < favoriteIds.length) ? i + 10 : favoriteIds.length;
        final batch = favoriteIds.sublist(i, end);

        QuerySnapshot querySnapshot = await _propertiesCollection
            .where('propertyId', whereIn: batch)
            .get();

        List<Property> batchProperties = querySnapshot.docs
            .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        favoriteProperties.addAll(batchProperties);
      }

      return favoriteProperties;
    } catch (e) {
      rethrow;
    }
  }

  // *** OWNER METHODS ***

  Future<void> createOwner(Owner owner) async {
    try {
      // First check if documents already exist
      final userDoc = await _usersCollection.doc(owner.uid).get();
      final ownerDoc = await _ownersCollection.doc(owner.uid).get();

      // Batch write to ensure both documents are created/updated atomically
      WriteBatch batch = _db.batch();

      // Prepare user data
      Map<String, dynamic> userData = {
        'email': owner.email,
        'fullName': owner.fullName,
        'phoneNumber': owner.phoneNumber,
        'registrationDate': owner.registrationDate,
        'isVerified': owner.isVerified,
        'userType': 'owner',
      };

      // Add profilePictureUrl if it exists
      if (owner.profilePictureUrl != null) {
        userData['profilePictureUrl'] = owner.profilePictureUrl;
      }

      // Prepare owner data
      Map<String, dynamic> ownerData = {
        'isVerifiedOwner': owner.isVerifiedOwner,
        'rating': owner.rating,
      };

      // Add optional fields if they exist
      if (owner.identityVerificationDoc != null) {
        ownerData['identityVerificationDoc'] = owner.identityVerificationDoc;
      }

      // Set or update the documents
      if (userDoc.exists) {
        batch.update(_usersCollection.doc(owner.uid), userData);
      } else {
        batch.set(_usersCollection.doc(owner.uid), userData);
      }

      if (ownerDoc.exists) {
        batch.update(_ownersCollection.doc(owner.uid), ownerData);
      } else {
        batch.set(_ownersCollection.doc(owner.uid), ownerData);
      }

      // Commit the batch
      await batch.commit();

      print('Owner created/updated successfully: ${owner.uid}');
    } catch (e) {
      print('Error creating/updating owner: $e');
      rethrow;
    }
  }

  Future<Owner> getOwner(String uid) async {
    try {
      // Get basic user data
      DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();

      // Check if user exists
      if (!userDoc.exists) {
        print('User not found: $uid');
        throw Exception('User not found');
      }

      // Get owner-specific data
      DocumentSnapshot ownerDoc = await _ownersCollection.doc(uid).get();

      // Check if owner exists
      if (!ownerDoc.exists) {
        print('Owner document not found. Creating default owner document...');

        // Create default owner document if it doesn't exist
        await _ownersCollection.doc(uid).set({
          'isVerifiedOwner': false,
          'rating': 0.0,
        });

        // Re-fetch the owner document
        ownerDoc = await _ownersCollection.doc(uid).get();
      }

      // Combine data
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> ownerData = ownerDoc.data() as Map<String, dynamic>;

      Map<String, dynamic> combinedData = {
        ...userData,
        ...ownerData,
      };

      return Owner.fromMap(combinedData, uid);
    } catch (e) {
      print('Error getting owner: $e');
      rethrow;
    }
  }

  Future<void> updateOwner(Owner owner) async {
    try {
      // Mettre à jour les informations de base
      await _usersCollection.doc(owner.uid).update({
        'fullName': owner.fullName,
        'phoneNumber': owner.phoneNumber,
        'profilePictureUrl': owner.profilePictureUrl,
        'isVerified': owner.isVerified,
      });

      // Mettre à jour les informations spécifiques au propriétaire
      await _ownersCollection.doc(owner.uid).update({
        'identityVerificationDoc': owner.identityVerificationDoc,
        'isVerifiedOwner': owner.isVerifiedOwner,
        'rating': owner.rating,
      });
    } catch (e) {
      rethrow;
    }
  }

  // *** PROPERTY METHODS ***

  Future<String> createProperty(Property property) async {
    try {
      // Ajout dans Firestore avec l'ID généré
      await _propertiesCollection.doc(property.propertyId).set(
          property.toMap());
      return property.propertyId;
    } catch (e) {
      rethrow;
    }
  }

  Future<Property> getProperty(String propertyId) async {
    try {
      DocumentSnapshot propertyDoc = await _propertiesCollection
          .doc(propertyId)
          .get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      return Property.fromMap(propertyDoc.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProperty(Property property) async {
    try {
      await _propertiesCollection.doc(property.propertyId).update(
          property.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      // Supprimer la propriété
      await _propertiesCollection.doc(propertyId).delete();

      // Supprimer également les candidatures liées à cette propriété
      QuerySnapshot applications = await _applicationsCollection
          .where('propertyId', isEqualTo: propertyId)
          .get();

      WriteBatch batch = _db.batch();
      for (DocumentSnapshot doc in applications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Property>> getPropertiesByOwner(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _propertiesCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs
          .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Property>> searchProperties({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    bool availableOnly = true,
    PropertyType? propertyType,
    double? latitude,
    double? longitude,
    double? radius, // km
  }) async
  {
    try {
      // Commencer avec une requête de base
      Query query = _propertiesCollection;

      // Ajouter les filtres supportés par Firestore
      if (availableOnly) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (propertyType != null) {
        query = query.where('type', isEqualTo: propertyType
            .toString()
            .split('.')
            .last);
      }

      // Exécuter la requête
      QuerySnapshot querySnapshot = await query.get();

      // Convertir les documents en objets Property
      List<Property> properties = querySnapshot.docs
          .map((doc) => Property.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Appliquer les filtres supplémentaires qui ne sont pas directement supportés par Firestore
      if (minBedrooms != null) {
        properties =
            properties.where((p) => p.bedrooms >= minBedrooms).toList();
      }

      if (maxBedrooms != null) {
        properties =
            properties.where((p) => p.bedrooms <= maxBedrooms).toList();
      }

      // Filtrer par distance si la localisation est fournie
      if (latitude != null && longitude != null && radius != null) {
        properties = properties.where((p) {
          // Vérifier si la propriété a des coordonnées
          if (p.latitude == null || p.longitude == null) return false;

          // Calculer la distance (formule de Haversine simplifiée)
          double distance = _calculateDistance(
              latitude, longitude, p.latitude!, p.longitude!);

          return distance <= radius;
        }).toList();
      }

      return properties;
    } catch (e) {
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2)
  {
    const double p = 0.017453292519943295; // Math.PI / 180
    const double earthRadius = 6371.0; // Rayon de la Terre en km

    double a = 0.5 -
        (0.5 *
            ((1 - cos((lat2 - lat1) * p)) +
                cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))));

    return 2 * earthRadius * asin(sqrt(a));
  }

  // *** APPLICATION METHODS ***

  Future<String> createApplication(RentalApplication application) async {
    try {
      await _applicationsCollection.doc(application.applicationId).set(
          application.toMap());
      return application.applicationId;
    } catch (e) {
      rethrow;
    }
  }

  Future<RentalApplication> getApplication(String applicationId) async {
    try {
      DocumentSnapshot applicationDoc = await _applicationsCollection.doc(
          applicationId).get();

      if (!applicationDoc.exists) {
        throw Exception('Application not found');
      }

      return RentalApplication.fromMap(
          applicationDoc.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateApplicationStatus(String applicationId,
      ApplicationStatus status,
      String? ownerResponse) async
  {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': status
            .toString()
            .split('.')
            .last,
        'ownerResponse': ownerResponse,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RentalApplication>> getApplicationsByStudent(
      String studentId) async
  {
    try {
      QuerySnapshot querySnapshot = await _applicationsCollection
          .where('studentId', isEqualTo: studentId)
          .get();

      return querySnapshot.docs
          .map((doc) =>
          RentalApplication.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RentalApplication>> getApplicationsByProperty(
      String propertyId) async
  {
    try {
      QuerySnapshot querySnapshot = await _applicationsCollection
          .where('propertyId', isEqualTo: propertyId)
          .get();

      return querySnapshot.docs
          .map((doc) =>
          RentalApplication.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RentalApplication>> getApplicationsByOwner(String ownerId) async {
    try {
      // D'abord, récupérer toutes les propriétés du propriétaire
      List<Property> ownerProperties = await getPropertiesByOwner(ownerId);
      List<String> propertyIds = ownerProperties
          .map((p) => p.propertyId)
          .toList();

      if (propertyIds.isEmpty) {
        return [];
      }

      List<RentalApplication> applications = [];

      // Firebase ne permet pas de faire une requête whereIn avec plus de 10 éléments
      for (int i = 0; i < propertyIds.length; i += 10) {
        final end = (i + 10 < propertyIds.length) ? i + 10 : propertyIds.length;
        final batch = propertyIds.sublist(i, end);

        QuerySnapshot querySnapshot = await _applicationsCollection
            .where('propertyId', whereIn: batch)
            .get();

        List<RentalApplication> batchApplications = querySnapshot.docs
            .map((doc) =>
            RentalApplication.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        applications.addAll(batchApplications);
      }

      return applications;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createReview(Review review) async {
    try {
      print('Creating review using fallback method: ${review.reviewId}');

      // Save the review to Firestore
      await _reviewsCollection.doc(review.reviewId).set(review.toMap());
      print('Review saved successfully using fallback method');

      // Update the property rating
      try {
        await updatePropertyRating(review.propertyId);
        print('Property rating updated from fallback method');
      } catch (e) {
        print('Error updating property rating from fallback method: $e');
        // Continue anyway
      }

      return review.reviewId;
    } catch (e) {
      print('Error in fallback createReview: $e');
      throw Exception('Failed to create review: $e');
    }
  }
  Future<Review> getReview(String reviewId) async {
    try {
      DocumentSnapshot reviewDoc = await _reviewsCollection.doc(reviewId).get();

      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      return Review.fromMap(reviewDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting review: $e');
      rethrow;
    }
  }

  Future<List<Review>> getReviewsByProperty(String propertyId) async {
    try {
      QuerySnapshot querySnapshot = await _reviewsCollection
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('reviewDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Review>> getReviewsByStudent(String studentId) async {
    try {
      QuerySnapshot querySnapshot = await _reviewsCollection
          .where('studentId', isEqualTo: studentId)
          .orderBy('reviewDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Review>> getReviewsByOwner(String ownerId) async {
    try {
      QuerySnapshot querySnapshot = await _reviewsCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('reviewDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOwnerRating(String ownerId) async {
    try {
      // Récupérer tous les avis pour ce propriétaire
      List<Review> reviews = await getReviewsByOwner(ownerId);

      if (reviews.isEmpty) {
        return;
      }

      // Calculer la note moyenne
      double totalRating = 0;
      for (Review review in reviews) {
        totalRating += review.rating;
      }
      double averageRating = totalRating / reviews.length;

      // Mettre à jour la note du propriétaire dans Firestore
      await _ownersCollection.doc(ownerId).update({
        'rating': averageRating,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId, String ownerId) async {
    try {
      await _reviewsCollection.doc(reviewId).delete();
      // Mettre à jour la note moyenne du propriétaire
      await updateOwnerRating(ownerId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePropertyRating(String propertyId) async {
    try {
      print('Updating rating for property: $propertyId');

      // 1. Get all reviews for this property
      final querySnapshot = await _reviewsCollection
          .where('propertyId', isEqualTo: propertyId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      print('Found ${reviews.length} reviews for this property');

      if (reviews.isEmpty) {
        // If no reviews, update the property with a null rating
        await _propertiesCollection.doc(propertyId).update({
          'rating': null,
        });
        print('No reviews found, rating set to null');
        return;
      }

      // 2. Calculate the average rating
      double totalRating = 0;
      for (final review in reviews) {
        totalRating += review.rating;
      }

      double averageRating = totalRating / reviews.length;

      // 3. Round to 1 decimal place
      averageRating = double.parse(averageRating.toStringAsFixed(1));

      print('Calculated average rating: $averageRating');

      // 4. Update the property
      await _propertiesCollection.doc(propertyId).update({
        'rating': averageRating,
      });

      print('Property rating updated successfully to: $averageRating');
    } catch (e) {
      print('Error updating property rating: $e');
      print('Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPropertyReviewsWithRating(String propertyId) async {
    try {
      // Get all reviews for this property
      final querySnapshot = await _reviewsCollection
          .where('propertyId', isEqualTo: propertyId)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      print('Found ${reviews.length} reviews for property $propertyId');

      // Calculate average rating locally
      double averageRating = 0;
      if (reviews.isNotEmpty) {
        double totalRating = 0;
        for (final review in reviews) {
          totalRating += review.rating;
        }
        averageRating = totalRating / reviews.length;
        averageRating = double.parse(averageRating.toStringAsFixed(1));
      }

      return {
        'reviews': reviews,
        'averageRating': reviews.isEmpty ? null : averageRating,
        'reviewCount': reviews.length
      };
    } catch (e) {
      print('Error getting property reviews with rating: $e');
      return {
        'reviews': <Review>[],
        'averageRating': null,
        'reviewCount': 0
      };
    }
  }

  Future<String> createReviewSafe(Review review) async {
    try {
      print('Creating review with safe method: ${review.reviewId}');

      // 1. Save the review
      await _reviewsCollection.doc(review.reviewId).set(review.toMap());
      print('Review saved successfully');

      // 2. Try to update the property rating
      try {
        await updatePropertyRating(review.propertyId);
        print('Property rating updated successfully');
      } catch (e) {
        print('Error updating property rating: $e');
        print('Using local rating calculation instead');

        // 3. Get the property rating locally
        final ratingData = await getPropertyReviewsWithRating(review.propertyId);
        double? newRating = ratingData['averageRating'];

        print('Locally calculated rating: $newRating');

        // 4. Create a notification with the local rating
        try {
          // Get property details
          final property = await getProperty(review.propertyId);

          // Get student name
          String studentName = 'A student';
          try {
            final studentDoc = await _usersCollection.doc(review.studentId).get();
            if (studentDoc.exists) {
              studentName = (studentDoc.data() as Map<String, dynamic>)['fullName'] ?? 'A student';
            }
          } catch (e) {
            print('Error getting student name: $e');
          }

          // Create notification text with locally calculated rating
          final notificationMessage = '$studentName rated your property "${property.title}" ${review.rating} stars. ' +
              (newRating != null ? 'New average rating: $newRating' : '');

          // Try to create notification
          final notification = Notification(
            userId: review.ownerId,
            title: 'New Review',
            message: notificationMessage,
            type: NotificationType.newReview,
            relatedItemId: review.reviewId,
            relatedItemType: 'review',
            senderId: review.studentId,
            senderName: studentName,
            senderPhotoUrl: null,
          );

          await _notificationsCollection.doc(notification.notificationId).set(notification.toMap());
          print('Notification created with local rating');
        } catch (notificationError) {
          print('Could not create notification: $notificationError');
          // We've at least saved the review
        }
      }

      return review.reviewId;
    } catch (e) {
      print('Error in createReviewSafe: $e');
      rethrow;
    }
  }
  Future<List<Review>> getReviewsByPropertyRobust(String propertyId) async {
    try {
      print('Getting reviews for property: $propertyId');

      // Try the ordered query first (requires index)
      try {
        final querySnapshot = await _reviewsCollection
            .where('propertyId', isEqualTo: propertyId)
            .orderBy('reviewDate', descending: true)
            .get();

        final reviews = querySnapshot.docs
            .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        print('Found ${reviews.length} reviews with ordered query');
        return reviews;
      } catch (e) {
        print('Error with ordered query: $e');
        print('Falling back to unordered query');

        // Fallback to simple query without order (doesn't require index)
        final querySnapshot = await _reviewsCollection
            .where('propertyId', isEqualTo: propertyId)
            .get();

        final reviews = querySnapshot.docs
            .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Sort reviews client-side by date
        reviews.sort((a, b) => b.reviewDate.compareTo(a.reviewDate));

        print('Found ${reviews.length} reviews with unordered query');
        return reviews;
      }
    } catch (e) {
      print('All review queries failed: $e');
      return [];
    }
  }
}