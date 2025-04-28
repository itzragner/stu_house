// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/common/custom_button.dart';
// import '../student/student_profile_setup_screen.dart';
// import '../owner/owner_profile_setup_screen.dart';
//
// class RegisterScreen extends StatefulWidget {
//   static const String routeName = '/register';
//
//   const RegisterScreen({Key? key}) : super(key: key);
//
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _fullNameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   bool _isStudent = true;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _fullNameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _register() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       try {
//         final authService = Provider.of<AuthService>(context, listen: false);
//         await authService.registerWithEmailAndPassword(
//           _emailController.text.trim(),
//           _passwordController.text,
//           _fullNameController.text.trim(),
//           _phoneController.text.trim(),
//           _isStudent,
//         );
//
//         // Navigation vers l'écran de configuration du profil
//         if (!mounted) return;
//
//         if (_isStudent) {
//           Navigator.pushReplacementNamed(
//             context,
//             StudentProfileSetupScreen.routeName,
//           );
//         } else {
//           Navigator.pushReplacementNamed(
//             context,
//             OwnerProfileSetupScreen.routeName,
//           );
//         }
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'Registration failed: ${e.toString()}';
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
//         title: const Text('Registration'),
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
//                   'Create your account',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
//                 TextFormField(
//                   controller: _fullNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Full name',
//                     prefixIcon: Icon(Icons.person),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your full name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     prefixIcon: Icon(Icons.email),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!value.contains('@')) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _phoneController,
//                   decoration: const InputDecoration(
//                     labelText: 'Phone',
//                     prefixIcon: Icon(Icons.phone),
//                   ),
//                   keyboardType: TextInputType.phone,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your phone number';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: const InputDecoration(
//                     labelText: 'Password',
//                     prefixIcon: Icon(Icons.lock),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a password';
//                     }
//                     if (value.length < 6) {
//                       return 'The password must be at least 6 characters long';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _confirmPasswordController,
//                   decoration: const InputDecoration(
//                     labelText: 'Confirm password',
//                     prefixIcon: Icon(Icons.lock_outline),
//                   ),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please confirm your password';
//                     }
//                     if (value != _passwordController.text) {
//                       return 'The passwords do not match';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   'I am:',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: RadioListTile<bool>(
//                         title: const Text('Student'),
//                         value: true,
//                         groupValue: _isStudent,
//                         onChanged: (value) {
//                           setState(() {
//                             _isStudent = value!;
//                           });
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: RadioListTile<bool>(
//                         title: const Text('Owner'),
//                         value: false,
//                         groupValue: _isStudent,
//                         onChanged: (value) {
//                           setState(() {
//                             _isStudent = value!;
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
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
//                   text: 'Register',
//                   onPressed: _register,
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
