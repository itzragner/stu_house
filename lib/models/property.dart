import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stu_house/models/review.dart';
import 'package:uuid/uuid.dart';

enum PropertyType {
  apartment,
  studio,
  house,
  sharedRoom,
  singleRoom,
  dormitory
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.house:
        return 'House';
      case PropertyType.sharedRoom:
        return 'Shared Room';
      case PropertyType.singleRoom:
        return 'Single Room';
      case PropertyType.dormitory:
        return 'Dormitory';
    }
  }

  static PropertyType fromString(String value) {
    return PropertyType.values.firstWhere(
          (e) => e.toString().split('.').last == value.toLowerCase(),
      orElse: () => PropertyType.apartment,
    );
  }
}

class Property {
  final String propertyId;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String address;
  final double? latitude;
  final double? longitude;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<String> amenities;
  final List<String> imageUrls;
  final bool isAvailable;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final PropertyType type;
  final double? rating;

  Property({
    String? propertyId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    this.latitude,
    this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    List<String>? amenities,
    List<String>? imageUrls,
    this.isAvailable = true,
    this.availableFrom,
    this.availableTo,
    required this.type,
    this.rating,

  }) :
        propertyId = propertyId ?? const Uuid().v4(),
        amenities = amenities ?? [],
        imageUrls = imageUrls ?? [];

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'type': type.toString().split('.').last,
      'rating': rating,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      propertyId: map['propertyId'],
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      area: (map['area'] ?? 0).toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      availableFrom: (map['availableFrom'] as Timestamp?)?.toDate(),
      availableTo: (map['availableTo'] as Timestamp?)?.toDate(),
      type: PropertyTypeExtension.fromString(map['type'] ?? 'apartment'),

    );
  }

  Property copyWith({
    String? propertyId,
    String? ownerId,
    String? title,
    String? description,
    double? price,
    String? address,
    double? latitude,
    double? longitude,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? amenities,
    List<String>? imageUrls,
    bool? isAvailable,
    DateTime? availableFrom,
    DateTime? availableTo,
    PropertyType? type,

  }) {
    return Property(
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      type: type ?? this.type,
      rating: rating ?? this.rating,
    );
  }

  // Ajouter une image
  Property addImage(String imageUrl) {
    if (!imageUrls.contains(imageUrl)) {
      List<String> newImageUrls = List.from(imageUrls)..add(imageUrl);
      return copyWith(imageUrls: newImageUrls);
    }
    return this;
  }

  // Ajouter une commodité
  Property addAmenity(String amenity) {
    if (!amenities.contains(amenity)) {
      List<String> newAmenities = List.from(amenities)..add(amenity);
      return copyWith(amenities: newAmenities);
    }
    return this;
  }

}

// models/application.dart
