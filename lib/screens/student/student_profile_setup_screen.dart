import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student.dart';
import '../../widgets/common/custom_button.dart';
import 'student_home_screen.dart';
import '../../config/themes.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  static const String routeName = '/student/profile-setup';

  const StudentProfileSetupScreen({Key? key}) : super(key: key);

  @override
  _StudentProfileSetupScreenState createState() => _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _studentIdController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _endOfStudies;
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _universityController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _selectEndOfStudiesDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endOfStudies ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null && picked != _endOfStudies) {
      setState(() {
        _endOfStudies = picked;
      });
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

        // Retrieve the current student
        Student student = await _databaseService.getStudent(userId);

        // Upload profile image if selected
        String? profilePictureUrl;
        if (_profileImage != null) {
          // This would call your storage service to upload the image
          // For now we'll assume this method exists in the database service
          profilePictureUrl = await _databaseService.uploadStudentImage(
            userId,
            _profileImage!,
          );
        }

        // Update student profile
        Student updatedStudent = student.copyWith(
          universityName: _universityController.text.trim(),
          studentId: _studentIdController.text.trim(),
          endOfStudies: _endOfStudies,
          profilePictureUrl: profilePictureUrl ?? student.profilePictureUrl,
        );

        await _databaseService.updateStudent(updatedStudent);

        if (!mounted) return;

        // Navigate to student home screen
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
                  'University Information',
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
                    onTap: _pickImage,
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
                    onPressed: _pickImage,
                    child: const Text('Add a photo'),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(
                    labelText: 'University or School',
                    prefixIcon: Icon(Icons.school),
                    hintText: 'e.g. Harvard University',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your university name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID (optional)',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'e.g. S123456',
                  ),
                ),
                const SizedBox(height: 16),
                // End of studies date
                GestureDetector(
                  onTap: _selectEndOfStudiesDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expected graduation date',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Select a date',
                      ),
                      controller: TextEditingController(
                        text: _endOfStudies != null
                            ? "${_endOfStudies!.day}/${_endOfStudies!.month}/${_endOfStudies!.year}"
                            : "",
                      ),
                      validator: (value) {
                        if (_endOfStudies == null) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
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