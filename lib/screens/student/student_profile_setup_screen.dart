// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../models/student.dart';
// import '../../widgets/common/custom_button.dart';
// import 'student_home_screen.dart';
//
// class StudentProfileSetupScreen extends StatefulWidget {
//   static const String routeName = '/student/profile-setup';
//
//   const StudentProfileSetupScreen({Key? key}) : super(key: key);
//
//   @override
//   _StudentProfileSetupScreenState createState() => _StudentProfileSetupScreenState();
// }
//
// class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _universityController = TextEditingController();
//   final _studentIdController = TextEditingController();
//   final DatabaseService _databaseService = DatabaseService();
//   DateTime? _endOfStudies;
//   File? _profileImage;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   @override
//   void dispose() {
//     _universityController.dispose();
//     _studentIdController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     try {
//       final ImagePicker _picker = ImagePicker();
//       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//       if (image != null) {
//         setState(() {
//           _profileImage = File(image.path);
//         });
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }
//
//   Future<void> _selectEndOfStudiesDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _endOfStudies ?? DateTime.now().add(const Duration(days: 365)),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
//     );
//
//     if (picked != null && picked != _endOfStudies) {
//       setState(() {
//         _endOfStudies = picked;
//       });
//     }
//   }
//
//   Future<void> _saveProfile() async {
//     if (_formKey.currentState!.validate()) {
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
//           throw Exception('Utilisateur non connecté');
//         }
//
//         // Récupérer l'étudiant actuel
//         Student student = await _databaseService.getStudent(userId);
//
//         // Mettre à jour les informations supplémentaires
//         String? profilePictureUrl;
//         if (_profileImage != null) {
//           // Télécharger la photo de profil
//           profilePictureUrl = await _databaseService.uploadStudentImage(
//             userId,
//             _profileImage!,
//           );
//         }
//
//         // Mettre à jour le profil étudiant
//         Student updatedStudent = student.copyWith(
//           universityName: _universityController.text.trim(),
//           studentId: _studentIdController.text.trim(),
//           endOfStudies: _endOfStudies,
//           profilePictureUrl: profilePictureUrl ?? student.profilePictureUrl,
//         );
//
//         await _databaseService.updateStudent(updatedStudent);
//
//         if (!mounted) return;
//
//         // Naviguer vers l'écran d'accueil étudiant
//         Navigator.pushReplacementNamed(context, StudentHomeScreen.routeName);
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'Erreur lors de la mise à jour du profil: ${e.toString()}';
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
//       appBar: AppBar(
//         title: const Text('Complétez votre profil'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Informations universitaires',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                   const SizedBox(height: 24),
//                 // Photo de profil
//                 Center(
//                   child: GestureDetector(
//                     onTap: _pickImage,
//                     child: CircleAvatar(
//                       radius: 60,
//                       backgroundColor: Colors.grey[300],
//                       backgroundImage: _profileImage != null
//                           ? FileImage(_profileImage!)
//                           : null,
//                       child: _profileImage == null
//                           ? const Icon(
//                         Icons.add_a_photo,
//                         size: 50,
//                         color: Colors.grey,
//                       )
//                           : null,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Center(
//                   child: TextButton(
//                     onPressed: _pickImage,
//                     child: const Text('Ajouter une photo'),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 TextFormField(
//                   controller: _universityController,
//                   decoration: const InputDecoration(
//                     labelText: 'Université ou École',
//                     prefixIcon: Icon(Icons.school),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Veuillez entrer le nom de votre université';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _studentIdController,
//                   decoration: const InputDecoration(
//                     labelText: 'Numéro étudiant (optionnel)',
//                     prefixIcon: Icon(Icons.badge),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Date de fin d'études
//                 GestureDetector(
//                   onTap: _selectEndOfStudiesDate,
//                   child: AbsorbPointer(
//                     child: TextFormField(
//                       decoration: const InputDecoration(
//                         labelText: 'Date de fin d\'études prévue',
//                         prefixIcon: Icon(Icons.calendar_today),
//                       ),
//                       controller: TextEditingController(
//                         text: _endOfStudies != null
//                             ? "${_endOfStudies!.day}/${_endOfStudies!.month}/${_endOfStudies!.year}"
//                             : "",
//                       ),
//                       validator: (value) {
//                         if (_endOfStudies == null) {
//                           return 'Veuillez sélectionner une date';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 if (_errorMessage != null)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 16),
//                     child: Text(
//                       _errorMessage!,
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontSize: 14,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 _isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : CustomButton(
//                   text: 'Enregistrer',
//                   onPressed: _saveProfile,
//                 ),
//                 const SizedBox(height: 16),
//                 TextButton(
//                   onPressed: () {
//                     // Passer directement à l'écran d'accueil sans compléter le profil
//                     Navigator.pushReplacementNamed(
//                       context,
//                       StudentHomeScreen.routeName,
//                     );
//                   },
//                   child: const Text('Compléter plus tard'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
