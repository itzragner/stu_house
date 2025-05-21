import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  DatabaseService()
      : _usersCollection = FirebaseFirestore.instance.collection('users'),
        _studentsCollection = FirebaseFirestore.instance.collection('students'),
        _ownersCollection = FirebaseFirestore.instance.collection('owners'),
        _propertiesCollection = FirebaseFirestore.instance.collection(
            'properties'),
        _applicationsCollection = FirebaseFirestore.instance.collection(
            'applications'),
        _reviewsCollection = FirebaseFirestore.instance.collection('reviews');

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

// Upload an owner image
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

// Upload a property image
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

  // Mettre à jour les informations d'un étudiant
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

  // Ajouter un logement aux favoris
  Future<void> addFavoriteProperty(String studentId, String propertyId) async {
    try {
      await _studentsCollection.doc(studentId).update({
        'favoritePropertyIds': FieldValue.arrayUnion([propertyId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Retirer un logement des favoris
  Future<void> removeFavoriteProperty(String studentId,
      String propertyId) async {
    try {
      await _studentsCollection.doc(studentId).update({
        'favoritePropertyIds': FieldValue.arrayRemove([propertyId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les logements favoris d'un étudiant
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

  // Mettre à jour les informations d'un propriétaire
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

  // Créer une nouvelle propriété
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

  // Récupérer une propriété par son ID
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

  // Mettre à jour une propriété
  Future<void> updateProperty(Property property) async {
    try {
      await _propertiesCollection.doc(property.propertyId).update(
          property.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une propriété
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

  // Récupérer les propriétés d'un propriétaire
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

  // Rechercher des propriétés selon des critères
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
  }) async {
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

  // Calculer la distance entre deux points (en km) - Formule de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    const double earthRadius = 6371.0; // Rayon de la Terre en km

    double a = 0.5 -
        (0.5 *
            ((1 - cos((lat2 - lat1) * p)) +
                cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))));

    return 2 * earthRadius * asin(sqrt(a));
  }

  // *** APPLICATION METHODS ***

  // Créer une nouvelle candidature
  Future<String> createApplication(RentalApplication application) async {
    try {
      await _applicationsCollection.doc(application.applicationId).set(
          application.toMap());
      return application.applicationId;
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une candidature par son ID
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

  // Mettre à jour le statut d'une candidature
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

  // Récupérer les candidatures d'un étudiant
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

  // Récupérer les candidatures pour une propriété
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

  // Récupérer les candidatures reçues par un propriétaire
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
      await _reviewsCollection.doc(review.reviewId).set(review.toMap());

      // Mettre à jour la note moyenne du propriétaire
      await updateOwnerRating(review.ownerId);

      return review.reviewId;
    } catch (e) {
      rethrow;
    }
  }

// Récupérer tous les avis pour une propriété
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

// Récupérer tous les avis d'un étudiant
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

// Récupérer tous les avis pour un propriétaire
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

// Mettre à jour la note moyenne d'un propriétaire
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

// Supprimer un avis
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
      // Récupérer tous les avis pour cette propriété
      List<Review> reviews = await getReviewsByProperty(propertyId);

      if (reviews.isEmpty) {
        // Si aucun avis, mettre à null
        await _propertiesCollection.doc(propertyId).update({
          'rating': null,
        });
        return;
      }

      // Calculer la note moyenne
      double totalRating = 0;
      for (Review review in reviews) {
        totalRating += review.rating;
      }
      double averageRating = totalRating / reviews.length;

      // Arrondir à 2 décimales
      averageRating = double.parse(averageRating.toStringAsFixed(2));

      // Mettre à jour la note de la propriété dans Firestore
      await _propertiesCollection.doc(propertyId).update({
        'rating': averageRating,
      });
    } catch (e) {
      rethrow;
    }
  }
}