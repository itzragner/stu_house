// Update lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Storage with explicit configuration
    FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 15));
    FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 15));

    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // We'll continue running the app, but Firebase functionality might not work
  }

  // Create the AuthService instance
  final authService = AuthService();

  // Sign in anonymously if no user is logged in
  if (authService.userId == null) {
    try {
      await authService.signInAnonymously();
      print("Automatically signed in anonymously");
    } catch (e) {
      print("Error with automatic anonymous sign-in: $e");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}