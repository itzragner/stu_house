import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/owner.dart';
import 'database_service.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
}

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final DatabaseService _database = DatabaseService();

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userId;
  String? _userType;

  // Getters
  AuthStatus get status => _status;
  String? get userId => _userId ?? _auth.currentUser?.uid;
  String? get userType => _userType;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isStudent => _userType == 'student';
  bool get isOwner => _userType == 'owner';

  // Constructor
  AuthService() {
    // Listen for authentication changes
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // Initialize state with current user if available
    _initializeWithCurrentUser();
  }

  // Initialize with current user if available
  Future<void> _initializeWithCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _onAuthStateChanged(currentUser);
    }
  }

  // Method called when auth state changes
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _userId = null;
      _userType = null;
    } else {
      _status = AuthStatus.loading;
      _userId = firebaseUser.uid;

      // Check if the user is anonymous (guest)
      if (firebaseUser.isAnonymous) {
        _status = AuthStatus.authenticated;
        _userType = 'guest';
      } else {
        // Fetch user type from Firestore
        try {
          _userType = await _database.getUserType(firebaseUser.uid);
          _status = AuthStatus.authenticated;
        } catch (e) {
          print('Error getting user type: $e');

          _status = AuthStatus.authenticated;
          _userType = 'unknown'; // Use a default type
        }
      }
    }

    notifyListeners();
  }

  // Anonymous sign in
  Future<bool> signInAnonymously() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _auth.signInAnonymously();

      // Allow time for the auth state listener to update
      await Future.delayed(Duration(milliseconds: 300));

      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      print('Attempting sign in: $email');

      // Attempt to sign in
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Wait for Firebase to complete the sign-in process
      await Future.delayed(Duration(milliseconds: 300));

      // Force refresh the user to ensure we get the latest data
      await _auth.currentUser?.reload();

      // Update our local state
      final user = _auth.currentUser;
      if (user != null) {
        _userId = user.uid;
        try {
          _userType = await _database.getUserType(user.uid);
          print('User type found: $_userType');

          // Validate that user records exist in Firestore
          if (_userType == 'student') {
            try {
              await _database.getStudent(user.uid);
              print('Student record confirmed in Firestore');
            } catch (e) {
              print('Error getting student record: $e. Creating default student record...');

              // Create a default student record if it doesn't exist
              Student student = Student(
                uid: user.uid,
                email: user.email ?? 'unknown',
                fullName: user.displayName ?? 'Unknown Student',
                phoneNumber: '',
                favoritePropertyIds: [],
              );

              await _database.createStudent(student);
            }
          } else if (_userType == 'owner') {
            try {
              await _database.getOwner(user.uid);
              print('Owner record confirmed in Firestore');
            } catch (e) {
              print('Error getting owner record: $e. Creating default owner record...');

              // Create a default owner record if it doesn't exist
              Owner owner = Owner(
                uid: user.uid,
                email: user.email ?? 'unknown',
                fullName: user.displayName ?? 'Unknown Owner',
                phoneNumber: '',
                isVerifiedOwner: false,
                rating: 0.0,
              );

              await _database.createOwner(owner);
            }
          }
        } catch (e) {
          print('Error getting user type: $e');
          _userType = 'unknown';
        }
        _status = AuthStatus.authenticated;
      } else {
        // This should not happen, but handle it just in case
        _status = AuthStatus.unauthenticated;
        _userId = null;
        _userType = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error in sign in: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }
  Future<bool> registerWithEmailAndPassword(
      String email,
      String password,
      String fullName,
      String phoneNumber,
      bool isStudent
      ) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      print('Registering new ${isStudent ? 'student' : 'owner'}: $email');

      // Create Firebase user
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID
      String uid = result.user!.uid;
      _userId = uid;

      print('Firebase user created: $uid');

      // Create user object in Firestore
      if (isStudent) {
        Student student = Student(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          favoritePropertyIds: [], // Initialize with empty array
        );

        await _database.createStudent(student);
        _userType = 'student';
        print('Student record created in Firestore');
      } else {
        Owner owner = Owner(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          isVerifiedOwner: false,
          rating: 0.0,
        );

        await _database.createOwner(owner);
        _userType = 'owner';
        print('Owner record created in Firestore');
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error in registration: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _auth.signOut();

      _status = AuthStatus.unauthenticated;
      _userId = null;
      _userType = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Check if a user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }
}