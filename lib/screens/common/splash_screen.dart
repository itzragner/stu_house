import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../student/student_home_screen.dart';
import '../owner/owner_home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Vérifier l'état de l'authentification après le chargement des animations
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Vérifier l'état d'authentification et naviguer en conséquence
  Future<void> _checkAuthAndNavigate() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isAuthenticated) {
      // L'utilisateur est déjà connecté, naviguer vers la page d'accueil appropriée
      if (authService.isStudent) {
        Navigator.of(context).pushReplacementNamed(StudentHomeScreen.routeName);
      } else if (authService.isOwner) {
        Navigator.of(context).pushReplacementNamed(StudentHomeScreen.routeName);
      }
    } else {
      // L'utilisateur n'est pas connecté, naviguer vers la page de connexion
      Navigator.of(context).pushReplacementNamed(StudentHomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de l'application
                    Icon(
                      Icons.home_work,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    // Nom de l'application
                    Text(
                      'StuHous',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Slogan
                    Text(
                      'Find the perfect accommodation for your studies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64),
                    // Indicateur de chargement
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}