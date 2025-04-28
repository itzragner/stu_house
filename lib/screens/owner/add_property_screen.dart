// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../models/property.dart';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../widgets/common/custom_button.dart';
//
// class AddPropertyScreen extends StatefulWidget {
//   static const String routeName = '/owner/add-property';
//
//   const AddPropertyScreen({Key? key}) : super(key: key);
//
//   @override
//   _AddPropertyScreenState createState() => _AddPropertyScreenState();
// }
//
// class _AddPropertyScreenState extends State<AddPropertyScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final DatabaseService _databaseService = DatabaseService();
//
//   // Contrôleurs pour les champs de formulaire
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _bedroomsController = TextEditingController(text: '1');
//   final _bathroomsController = TextEditingController(text: '1');
//   final _areaController = TextEditingController();
//
//   // Valeurs par défaut
//   PropertyType _selectedType = PropertyType.apartment;
//   List<String> _amenities = [];
//   List<File> _selectedImages = [];
//   DateTime? _availableFrom;
//   DateTime? _availableTo;
//
//   // Liste des commodités disponibles
//   final List<String> _availableAmenities = [
//     'WiFi',
//     'Equipped kitchen',
//     'Washing machine',
//     'Dishwasher',
//     'TV',
//     'Parking',
//     'Air conditioning',
//     'Heating',
//     'Balcony',
//     'Lift',
//     'Gym',
//     'Security 24/7',
//     'Furnished',
//     'Disability-accessible',
//   ];
//
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _addressController.dispose();
//     _bedroomsController.dispose();
//     _bathroomsController.dispose();
//     _areaController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImages() async {
//     try {
//       final ImagePicker _picker = ImagePicker();
//       final List<XFile> images = await _picker.pickMultiImage();
//
//       if (images.isNotEmpty) {
//         setState(() {
//           _selectedImages.addAll(images.map((xFile) => File(xFile.path)).toList());
//         });
//       }
//     } catch (e) {
//       print('Error picking images: $e');
//     }
//   }
//
//   Future<void> _selectAvailableFromDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _availableFrom ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
//     );
//
//     if (picked != null && (_availableTo == null || picked.isBefore(_availableTo!))) {
//       setState(() {
//         _availableFrom = picked;
//       });
//     } else if (picked != null && _availableTo != null && picked.isAfter(_availableTo!)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('The availability date must be earlier than the end date'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _selectAvailableToDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _availableTo ?? (_availableFrom?.add(const Duration(days: 180)) ?? DateTime.now().add(const Duration(days: 180))),
//       firstDate: _availableFrom ?? DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _availableTo = picked;
//       });
//     }
//   }
//
//   void _toggleAmenity(String amenity) {
//     setState(() {
//       if (_amenities.contains(amenity)) {
//         _amenities.remove(amenity);
//       } else {
//         _amenities.add(amenity);
//       }
//     });
//   }
//
//   void _removeImage(int index) {
//     setState(() {
//       _selectedImages.removeAt(index);
//     });
//   }
//
//   Future<void> _saveProperty() async {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedImages.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please add at least one photo'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       try {
//         final authService = Provider.of<AuthService>(context, listen: false);
//         final userId = authService.userId;
//
//         if (userId == null) {
//           throw Exception('User not logged in');
//         }
//
//         // Créer une nouvelle propriété
//         Property newProperty = Property(
//           ownerId: userId,
//           title: _titleController.text.trim(),
//           description: _descriptionController.text.trim(),
//           price: double.parse(_priceController.text),
//           address: _addressController.text.trim(),
//           bedrooms: int.parse(_bedroomsController.text),
//           bathrooms: int.parse(_bathroomsController.text),
//           area: double.parse(_areaController.text),
//           amenities: _amenities,
//           imageUrls: [], // À remplir après le téléchargement
//           isAvailable: true,
//           availableFrom: _availableFrom,
//           availableTo: _availableTo,
//           type: _selectedType,
//         );
//
//         // Enregistrer la propriété dans Firestore
//         final propertyId = await _databaseService.createProperty(newProperty);
//
//         // Télécharger les images
//         List<String> imageUrls = [];
//         for (File image in _selectedImages) {
//           final imageUrl = await _databaseService.uploadPropertyImage(
//             propertyId,
//             image,
//           );
//           imageUrls.add(imageUrl);
//         }
//
//         // Mettre à jour la propriété avec les URLs des images
//         Property updatedProperty = newProperty.copyWith(
//           propertyId: propertyId,
//           imageUrls: imageUrls,
//         );
//
//         await _databaseService.updateProperty(updatedProperty);
//
//         if (!mounted) return;
//
//         // Afficher un message de succès et revenir à l'écran précédent
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Property successfully added'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'Error while adding: ${e.toString()}';
//         });
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//         title: const Text('Add a property'),
//     centerTitle: true,
//     ),
//     body: _isLoading
//     ? const Center(child: CircularProgressIndicator())
//         : Form(
//     key: _formKey,
//     child: SingleChildScrollView(
//     padding: const EdgeInsets.all(16),
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     // Section photos
//     const Text(
//     'Photos',
//     style: TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     const SizedBox(height: 8),
//     const Text(
//     'Add photos to attract students attention',
//     style: TextStyle(
//     color: Colors.grey,
//     ),
//     ),
//     const SizedBox(height: 16),
//     _buildImagesSection(),
//     const SizedBox(height: 24),
//     const Divider(),
//     const SizedBox(height: 16),
//
//     // Informations de base
//     const Text(
//     'Basic information',
//     style: TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     const SizedBox(height: 16),
//     TextFormField(
//     controller: _titleController,
//     decoration: const InputDecoration(
//     labelText: 'Title',
//     hintText: 'Example: Beautiful apartment near the campus',
//     ),
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter a title';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 16),
//     TextFormField(
//     controller: _descriptionController,
//     decoration: const InputDecoration(
//     labelText: 'Description',
//     hintText: 'Describe your property...',
//     alignLabelWithHint: true,
//     ),
//     maxLines: 5,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter a description';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 16),
//     TextFormField(
//     controller: _addressController,
//     decoration: const InputDecoration(
//     labelText: 'Adress',
//     hintText: 'Full address of the property',
//     ),
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter an address';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 16),
//
//     // Type de logement
//     const Text(
//     'Type of property',
//     style: TextStyle(
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     const SizedBox(height: 8),
//     DropdownButtonFormField<PropertyType>(
//     value: _selectedType,
//     decoration: const InputDecoration(
//     border: OutlineInputBorder(),
//     ),
//     items: PropertyType.values.map((type) {
//     return DropdownMenuItem<PropertyType>(
//     value: type,
//     child: Text(type.displayName),
//     );
//     }).toList(),
//     onChanged: (value) {
//     if (value != null) {
//     setState(() {
//     _selectedType = value;
//     });
//     }
//     },
//     ),
//     const SizedBox(height: 24),
//     const Divider(),
//     const SizedBox(height: 16),
//
//     // Caractéristiques et prix
//     const Text(
//     'Features and price',
//     style: TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     const SizedBox(height: 16),
//
//     // Prix
//     TextFormField(
//     controller: _priceController,
//     decoration: const InputDecoration(
//     labelText: 'Monthly price (€)',
//     prefixIcon: Icon(Icons.euro),
//     ),
//     keyboardType: TextInputType.number,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter a price';
//     }
//     if (double.tryParse(value) == null) {
//     return 'Please enter a valid number';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 16),
//
//     // Chambres et salles de bain
//     Row(
//     children: [
//     Expanded(
//     child: TextFormField(
//     controller: _bedroomsController,
//     decoration: const InputDecoration(
//     labelText: 'Rooms',
//     prefixIcon: Icon(Icons.bed),
//     ),
//     keyboardType: TextInputType.number,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Required';
//     }
//     if (int.tryParse(value) == null) {
//     return 'Number';
//     }
//     return null;
//     },
//     ),
//     ),
//     const SizedBox(width: 16),
//     Expanded(
//     child: TextFormField(
//     controller: _bathroomsController,
//     decoration: const InputDecoration(
//     labelText: 'Bathrooms',
//     prefixIcon: Icon(Icons.bathtub),
//     ),
//     keyboardType: TextInputType.number,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Required';
//     }
//     if (int.tryParse(value) == null) {
//     return 'Number';
//     }
//
//     return null;
//     },
//     ),
//     ),
//     ],
//     ),
//       const SizedBox(height: 16),
//
//       // Surface
//       TextFormField(
//         controller: _areaController,
//         decoration: const InputDecoration(
//           labelText: 'Area (m²)',
//           prefixIcon: Icon(Icons.square_foot),
//         ),
//         keyboardType: TextInputType.number,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter an area';
//           }
//           if (double.tryParse(value) == null) {
//             return 'Please enter a valid number';
//           }
//           return null;
//         },
//       ),
//       const SizedBox(height: 24),
//       const Divider(),
//       const SizedBox(height: 16),
//
//       // Disponibilité
//       const Text(
//         'Availability',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       const SizedBox(height: 16),
//
//       // Date de début
//       GestureDetector(
//         onTap: _selectAvailableFromDate,
//         child: AbsorbPointer(
//           child: TextFormField(
//             decoration: const InputDecoration(
//               labelText: 'Available from',
//               prefixIcon: Icon(Icons.calendar_today),
//               hintText: 'Select a date',
//             ),
//             controller: TextEditingController(
//               text: _availableFrom != null
//                   ? "${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}"
//                   : "",
//             ),
//           ),
//         ),
//       ),
//       const SizedBox(height: 16),
//
//       // Date de fin (optionnelle)
//       GestureDetector(
//         onTap: _selectAvailableToDate,
//         child: AbsorbPointer(
//           child: TextFormField(
//             decoration: const InputDecoration(
//               labelText: 'Available until (optional)',
//               prefixIcon: Icon(Icons.event),
//               hintText: 'Select a date',
//             ),
//             controller: TextEditingController(
//               text: _availableTo != null
//                   ? "${_availableTo!.day}/${_availableTo!.month}/${_availableTo!.year}"
//                   : "",
//             ),
//           ),
//         ),
//       ),
//       const SizedBox(height: 24),
//       const Divider(),
//       const SizedBox(height: 16),
//
//       // Commodités
//       const Text(
//         'Amenities',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       const SizedBox(height: 8),
//       const Text(
//         'Select the amenities available in the property',
//         style: TextStyle(
//           color: Colors.grey,
//         ),
//       ),
//       const SizedBox(height: 16),
//       _buildAmenitiesGrid(),
//       const SizedBox(height: 32),
//
//       // Message d'erreur
//       if (_errorMessage != null)
//         Padding(
//           padding: const EdgeInsets.only(bottom: 16),
//           child: Text(
//             _errorMessage!,
//             style: const TextStyle(
//               color: Colors.red,
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//
//       // Bouton d'enregistrement
//       CustomButton(
//         text: 'Publish the property',
//         onPressed: _saveProperty,
//       ),
//       const SizedBox(height: 32),
//     ],
//     ),
//     ),
//     ),
//     );
//   }
//
//   Widget _buildImagesSection() {
//     return Column(
//       children: [
//         if (_selectedImages.isEmpty)
//           GestureDetector(
//             onTap: _pickImages,
//             child: Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: Colors.grey[400]!,
//                   width: 1,
//                   style: BorderStyle.dashed,
//                 ),
//               ),
//               child: const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.add_photo_alternate,
//                       size: 50,
//                       color: Colors.grey,
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Click to add photos',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//         else
//           Column(
//             children: [
//               SizedBox(
//                 height: 200,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _selectedImages.length + 1, // +1 pour le bouton d'ajout
//                   itemBuilder: (context, index) {
//                     if (index == _selectedImages.length) {
//                       // Bouton pour ajouter plus d'images
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 8),
//                         child: GestureDetector(
//                           onTap: _pickImages,
//                           child: Container(
//                             width: 150,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                 color: Colors.grey[400]!,
//                                 width: 1,
//                                 style: BorderStyle.dashed,
//                               ),
//                             ),
//                             child: const Center(
//                               child: Icon(
//                                 Icons.add_photo_alternate,
//                                 size: 40,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     }
//
//                     // Afficher l'image avec un bouton de suppression
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.file(
//                               _selectedImages[index],
//                               width: 150,
//                               height: 200,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: GestureDetector(
//                               onTap: () => _removeImage(index),
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.close,
//                                   size: 16,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 '${_selectedImages.length} picture${_selectedImages.length > 1 ? 's' : ''} selected${_selectedImages.length > 1 ? 's' : ''}',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }
//
//   Widget _buildAmenitiesGrid() {
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: _availableAmenities.map((amenity) {
//         final isSelected = _amenities.contains(amenity);
//         return GestureDetector(
//           onTap: () => _toggleAmenity(amenity),
//           child: Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 8,
//             ),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? Theme.of(context).primaryColor.withOpacity(0.1)
//                   : Colors.grey[200],
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey[400]!,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   isSelected ? Icons.check_circle : Icons.circle_outlined,
//                   size: 16,
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey[600],
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   amenity,
//                   style: TextStyle(
//                     color: isSelected
//                         ? Theme.of(context).primaryColor
//                         : Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }