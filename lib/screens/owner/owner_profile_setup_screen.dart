// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../models/owner.dart';
// import '../../widgets/common/custom_button.dart';
// import 'owner_home_screen.dart';
//
// class OwnerProfileSetupScreen extends StatefulWidget {
//   static const String routeName = '/owner/profile-setup';
//
//   const OwnerProfileSetupScreen({Key? key}) : super(key: key);
//
//   @override
//   _OwnerProfileSetupScreenState createState() => _OwnerProfileSetupScreenState();
// }
//
// class _OwnerProfileSetupScreenState extends State<OwnerProfileSetupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final DatabaseService _databaseService = DatabaseService();
//   File? _profileImage;
//   File? _identityDocument;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   Future<void> _pickProfileImage() async {
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
//       print('Error picking profile image: $e');
//     }
//   }
//
//   Future<void> _pickIdentityDocument() async {
//     try {
//       final ImagePicker _picker = ImagePicker();
//       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//       if (image != null) {
//         setState(() {
//           _identityDocument = File(image.path);
//         });
//       }
//     } catch (e) {
//       print('Error picking identity document: $e');
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
//         // Récupérer le propriétaire actuel
//         Owner owner = await _databaseService.getOwner(userId);
//
//         // Télécharger les images
//         String? profilePictureUrl;
//         String? identityDocumentUrl;
//
//         if (_profileImage != null) {
//           // Télécharger la photo de profil
//           profilePictureUrl = await _databaseService.uploadOwnerImage(
//             userId,
//             _profileImage!,
//             'profile',
//           );
//         }
//
//         if (_identityDocument != null) {
//           // Télécharger le document d'identité
//           identityDocumentUrl = await _databaseService.uploadOwnerImage(
//             userId,
//             _identityDocument!,
//             'identity',
//           );
//         }
//
//         // Mettre à jour le profil propriétaire
//         Owner updatedOwner = owner.copyWith(
//           profilePictureUrl: profilePictureUrl ?? owner.profilePictureUrl,
//           identityVerificationDoc: identityDocumentUrl ?? owner.identityVerificationDoc,
//         );
//
//         await _databaseService.updateOwner(updatedOwner);
//
//         if (!mounted) return;
//
//         // Naviguer vers l'écran d'accueil propriétaire
//         Navigator.pushReplacementNamed(context, OwnerHomeScreen.routeName);
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
//               children: [
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Informations propriétaire',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 // Photo de profil
//                 Center(
//                   child: GestureDetector(
//                     onTap: _pickProfileImage,
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
//                     onPressed: _pickProfileImage,
//                     child: const Text('Ajouter une photo'),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 // Document d'identité
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const Text(
//                         'Document d\'identité',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Pour vérifier votre identité et assurer la sécurité des étudiants, veuillez télécharger une pièce d\'identité (carte d\'identité, passeport, permis de conduire).',
//                         style: TextStyle(fontSize: 14),
//                       ),
//                       const SizedBox(height: 16),
//                       if (_identityDocument != null)
//                         Container(
//                           height: 150,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             image: DecorationImage(
//                               image: FileImage(_identityDocument!),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         )
//                       else
//                         GestureDetector(
//                           onTap: _pickIdentityDocument,
//                           child: Container(
//                             height: 150,
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
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.add_photo_alternate,
//                                     size: 40,
//                                     color: Colors.grey,
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'Cliquez pour télécharger',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       const SizedBox(height: 8),
//                       if (_identityDocument != null)
//                         TextButton.icon(
//                           onPressed: _pickIdentityDocument,
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Changer de document'),
//                         ),
//                     ],
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
//                       OwnerHomeScreen.routeName,
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