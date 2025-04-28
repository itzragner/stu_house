// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/common/custom_button.dart';
// import '../../widgets/common/loading_indicator.dart';
// import 'register_screen.dart';
// import 'forgot_password_screen.dart';
// import '../student/student_home_screen.dart';
// import '../owner/owner_home_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   static const String routeName = '/login';
//
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//
//       try {
//         final authService = Provider.of<AuthService>(context, listen: false);
//         await authService.signInWithEmailAndPassword(
//           _emailController.text.trim(),
//           _passwordController.text,
//         );
//
//         // Navigation vers l'écran approprié selon le type d'utilisateur
//         if (!mounted) return;
//
//         if (authService.isStudent) {
//           Navigator.pushReplacementNamed(context, StudentHomeScreen.routeName);
//         } else if (authService.isOwner) {
//           Navigator.pushReplacementNamed(context, OwnerHomeScreen.routeName);
//         }
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'Login failed: ${e.toString()}';
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
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const SizedBox(height: 32),
//                   Icon(
//                     Icons.home_work,
//                     size: 80,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'Welcome !',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Log in to access your account',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 32),
//                   TextFormField(
//                     controller: _emailController,
//                     decoration: const InputDecoration(
//                       labelText: 'Email',
//                       prefixIcon: Icon(Icons.email),
//                     ),
//                     keyboardType: TextInputType.emailAddress,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your email';
//                       }
//                       if (!value.contains('@')) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _passwordController,
//                     decoration: const InputDecoration(
//                       labelText: 'Password',
//                       prefixIcon: Icon(Icons.lock),
//                     ),
//                     obscureText: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.pushNamed(
//                           context,
//                           ForgotPasswordScreen.routeName,
//                         );
//                       },
//                       child: const Text('Forgot password?'),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   if (_errorMessage != null)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Text(
//                         _errorMessage!,
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : CustomButton(
//                     text: 'Log in',
//                     onPressed: _login,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text(Don't have an account?'),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushNamed(
//                             context,
//                             RegisterScreen.routeName,
//                           );
//                         },
//                         child: const Text('Sign up'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
