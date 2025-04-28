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

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      print("Signed in anonymously");
      notifyListeners();
    } catch (e) {
      print("Error signing in anonymously: $e");
      rethrow;
    }
  }

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userId;
  String? _userType;

  // Getters
  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get userType => _userType;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isStudent => _userType == 'student';
  bool get isOwner => _userType == 'owner';

  // Constructeur
  AuthService() {
    // Écouter les changements d'authentification
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Méthode appelée lorsque l'état d'authentification change
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _userId = null;
      _userType = null;
    } else {
      _status = AuthStatus.loading;
      _userId = firebaseUser.uid;
      // Récupérer le type d'utilisateur depuis Firestore
      try {
        _userType = await _database.getUserType(firebaseUser.uid);
        _status = AuthStatus.authenticated;
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        _userId = null;
        _userType = null;
      }
    }
    notifyListeners();
  }

  // Connexion avec email et mot de passe
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Le reste est géré par le listener _onAuthStateChanged
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Inscription d'un nouvel utilisateur
  Future<void> registerWithEmailAndPassword(
      String email,
      String password,
      String fullName,
      String phoneNumber,
      bool isStudent
      ) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      // Créer un utilisateur Firebase
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtenir l'ID utilisateur
      String uid = result.user!.uid;

      // Créer l'objet utilisateur dans Firestore
      if (isStudent) {
        Student student = Student(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
        );
        await _database.createStudent(student);
      } else {
        Owner owner = Owner(
          uid: uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
        );
        await _database.createOwner(owner);
      }

      // Le reste est géré par le listener _onAuthStateChanged
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Le reste est géré par le listener _onAuthStateChanged
    } catch (e) {
      rethrow;
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier si un utilisateur est connecté
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}