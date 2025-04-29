import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/owner.dart';
import '../../widgets/common/custom_button.dart';
import 'owner_home_screen.dart';
import '../../config/themes.dart';
import '../student/student_home_screen.dart';

class OwnerProfileSetupScreen extends StatefulWidget {
  static const String routeName = '/owner/profile-setup';

  const OwnerProfileSetupScreen({Key? key}) : super(key: key);

  @override
  _OwnerProfileSetupScreenState createState() => _OwnerProfileSetupScreenState();
}

class _OwnerProfileSetupScreenState extends State<OwnerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  File? _profileImage;
  File? _identityDocument;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _pickIdentityDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _identityDocument = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking identity document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting document: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.userId;

        if (userId == null) {
          throw Exception('User not logged in');
        }

        // Retrieve current owner
        Owner owner = await _databaseService.getOwner(userId);

        // Upload images
        String? profilePictureUrl;
        String? identityDocumentUrl;

        if (_profileImage != null) {
          // Upload profile picture
          profilePictureUrl = await _databaseService.uploadOwnerImage(
            userId,
            _profileImage!,
            'profile',
          );
        }

        if (_identityDocument != null) {
          // Upload identity document
          identityDocumentUrl = await _databaseService.uploadOwnerImage(
            userId,
            _identityDocument!,
            'identity',
          );
        }

        // Update owner profile
        Owner updatedOwner = owner.copyWith(
          profilePictureUrl: profilePictureUrl ?? owner.profilePictureUrl,
          identityVerificationDoc: identityDocumentUrl ?? owner.identityVerificationDoc,
        );

        await _databaseService.updateOwner(updatedOwner);

        if (!mounted) return;

        // Navigate to owner home screen - for this demo we'll use StudentHomeScreen
        Navigator.pushReplacementNamed(context, StudentHomeScreen.routeName);
      } catch (e) {
        setState(() {
          _errorMessage = 'Error updating profile: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Property Owner Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Profile photo
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickProfileImage,
                    child: const Text('Add a photo'),
                  ),
                ),
                const SizedBox(height: 24),

                // Identity verification section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Identity Verification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To ensure safety and trust, please upload a photo ID (passport, driver\'s license or identity card).',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (_identityDocument != null)
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_identityDocument!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _pickIdentityDocument,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload ID Document',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_identityDocument != null)
                        TextButton.icon(
                          onPressed: _pickIdentityDocument,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Change document'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                  text: 'Save Profile',
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Skip profile setup and go to home screen
                    Navigator.pushReplacementNamed(
                      context,
                      StudentHomeScreen.routeName,
                    );
                  },
                  child: const Text('Complete Later'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}